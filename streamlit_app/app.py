import pandas as pd
import plotly.express as px
import psycopg2
import streamlit as st

st.set_page_config(page_title="NYC Taxi Trip Analysis", page_icon="🚕", layout="wide")


@st.cache_resource
def get_redshift_connection():
    try:
        conn = psycopg2.connect(**st.secrets["redshift"])
        return conn
    except Exception as e:
        st.error(f"Error connecting to Redshift: {e}")
        return None


@st.cache_data
def load_kpi_data():
    conn = get_redshift_connection()
    if conn:
        try:
            query = 'SELECT * FROM "marts"."kpi_trip_duration_by_weather"'
            df = pd.read_sql_query(query, conn)
            st.success("Connected to Redshift and loaded data successfully!")
            return df
        except Exception as e:
            st.error(f"Error loading data: {e}")
            return pd.DataFrame()
    return pd.DataFrame()


st.title("🚕 NYC Taxi Dashboard: Trip Duration Analysis")
st.markdown("Analyzing the impact of weather on taxi trip durations across different NYC boroughs.")

df = load_kpi_data()

if not df.empty:
    st.sidebar.header("Filter Your Analysis")

    pickup_borough = st.sidebar.selectbox(
        "Select Pickup Borough:",
        options=sorted(df["pickup_borough"].unique()),
        index=0,
    )

    borough_filtered_df = df[df["pickup_borough"] == pickup_borough].copy()

    all_years = sorted(borough_filtered_df["trip_year"].unique())
    selected_years = st.sidebar.multiselect("Select Year(s):", options=all_years, default=all_years)

    all_months = sorted(borough_filtered_df["trip_month"].unique())
    selected_months = st.sidebar.multiselect(
        "Select Month(s):", options=all_months, default=all_months
    )

    st.sidebar.markdown("---")  # Visual separator

    # --- NEW TOGGLE LOGIC ---
    all_dropoff_boroughs = sorted(borough_filtered_df["dropoff_borough"].unique())
    compare_all = st.sidebar.toggle("Compare All Dropoff Boroughs", value=True)

    if compare_all:
        selected_dropoff_boroughs = all_dropoff_boroughs
    else:
        selected_dropoff_boroughs = st.sidebar.multiselect(
            "Select Specific Dropoff Borough(s):",
            options=all_dropoff_boroughs,
            default=all_dropoff_boroughs,
        )
    # --- END NEW LOGIC ---

    filtered_df = borough_filtered_df[
        (borough_filtered_df["trip_year"].isin(selected_years))
        & (borough_filtered_df["trip_month"].isin(selected_months))
        & (borough_filtered_df["dropoff_borough"].isin(selected_dropoff_boroughs))
    ].copy()

    st.header(f"Analysis for Trips from {pickup_borough}")

    if not filtered_df.empty:
        overall_trip_count = filtered_df["trip_count"].sum()

        weighted_median_df = filtered_df.loc[filtered_df.index.repeat(filtered_df.trip_count)]
        overall_median_duration = weighted_median_df["median_trip_duration"].median()

        busiest_route_df = filtered_df.groupby("dropoff_borough")["trip_count"].sum().reset_index()
        busiest_route = busiest_route_df.loc[busiest_route_df["trip_count"].idxmax()]

        col1, col2, col3 = st.columns(3)
        col1.metric("Total Trips Analyzed", f"{overall_trip_count:,.0f}")
        col2.metric("Overall Median Duration", f"{overall_median_duration:.1f} min")
        col3.metric(
            "Busiest Route",
            f"{busiest_route['dropoff_borough']}",
            f"{busiest_route['trip_count']:,} Trips",
        )

        st.markdown("---")
        st.subheader("Median Trip Duration by Weather")

        category_order = ["No Rain", "Light Rain", "Moderate Rain", "Heavy Rain"]
        filtered_df["precipitation_category"] = pd.Categorical(
            filtered_df["precipitation_category"], categories=category_order, ordered=True
        )

        chart_df = (
            filtered_df.groupby(["dropoff_borough", "precipitation_category"], observed=False)
            .agg(
                median_trip_duration=("median_trip_duration", "median"),
            )
            .reset_index()
        )

        fig = px.bar(
            chart_df,
            x="dropoff_borough",
            y="median_trip_duration",
            color="precipitation_category",
            barmode="group",
            labels={
                "dropoff_borough": "Dropoff Borough",
                "median_trip_duration": "Median Trip Duration (Minutes)",
                "precipitation_category": "Precipitation",
            },
            color_discrete_map={
                "No Rain": "#5A9A78",
                "Light Rain": "#4682B4",
                "Moderate Rain": "#FFA500",
                "Heavy Rain": "#DC143C",
            },
            text_auto=".1f",
        )

        fig.update_layout(
            title_text=f"Median Trip Duration from {pickup_borough}",
            title_x=0.5,
            legend_title_text="Precipitation",
            plot_bgcolor="rgba(0,0,0,0)",
            paper_bgcolor="rgba(0,0,0,0)",
            font=dict(color="white"),
            yaxis=dict(gridcolor="rgba(255, 255, 255, 0.2)"),
        )
        fig.update_traces(textangle=0, textposition="outside", cliponaxis=False)

        st.plotly_chart(fig, use_container_width=True)

        with st.expander("Show Filtered Data Table"):
            st.dataframe(filtered_df)
    else:
        st.warning(
            "No data available for the selected filters. Please expand your filter criteria."
        )
else:
    st.warning("No data loaded from Redshift. Please check the connection and data availability.")
