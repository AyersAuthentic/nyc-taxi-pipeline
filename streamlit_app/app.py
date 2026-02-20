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
def load_filtered_kpi_data(pickup_borough=None, years=None, months=None, dropoff_boroughs=None):
    """
    Load KPI data with server-side filtering to reduce data transfer and improve performance.

    Args:
        pickup_borough: Single pickup borough to filter by
        years: List of years to include
        months: List of months to include
        dropoff_boroughs: List of dropoff boroughs to include
    """
    conn = get_redshift_connection()
    if conn:
        try:
            # Build dynamic query with filters
            query = 'SELECT * FROM "marts"."kpi_trip_duration_by_weather" WHERE 1=1'
            params = []

            if pickup_borough:
                query += " AND pickup_borough = %s"
                params.append(str(pickup_borough))

            if years:
                placeholders = ",".join(["%s"] * len(years))
                query += f" AND trip_year IN ({placeholders})"
                # Convert numpy types to Python int
                params.extend([int(year) for year in years])

            if months:
                placeholders = ",".join(["%s"] * len(months))
                query += f" AND trip_month IN ({placeholders})"
                # Convert numpy types to Python int
                params.extend([int(month) for month in months])

            if dropoff_boroughs:
                placeholders = ",".join(["%s"] * len(dropoff_boroughs))
                query += f" AND dropoff_borough IN ({placeholders})"
                # Convert to Python strings
                params.extend([str(borough) for borough in dropoff_boroughs])

            # Execute parameterized query
            df = pd.read_sql_query(query, conn, params=params)

            if not df.empty:
                st.success(
                    f"Connected to Redshift and loaded {len(df):,} filtered records successfully!"
                )
            else:
                st.warning("No data found for the selected filters.")

            return df
        except Exception as e:
            st.error(f"Error loading data: {e}")
            return pd.DataFrame()
    return pd.DataFrame()


@st.cache_data
def load_initial_filter_options():
    """
    Load unique filter options for dropdowns with minimal data transfer.
    """
    conn = get_redshift_connection()
    if conn:
        try:
            query = """
                SELECT DISTINCT
                    pickup_borough,
                    trip_year,
                    trip_month,
                    dropoff_borough
                FROM "marts"."kpi_trip_duration_by_weather"
                ORDER BY pickup_borough, trip_year, trip_month, dropoff_borough
            """
            df = pd.read_sql_query(query, conn)
            return df
        except Exception as e:
            st.error(f"Error loading filter options: {e}")
            return pd.DataFrame()
    return pd.DataFrame()


st.title("🚕 NYC Taxi Dashboard: Trip Duration Analysis")
st.markdown("Analyzing the impact of weather on taxi trip durations across different NYC boroughs.")

# Load filter options first (lightweight query)
filter_options_df = load_initial_filter_options()

if not filter_options_df.empty:
    st.sidebar.header("Filter Your Analysis")

    # Get unique values for filters
    pickup_boroughs = sorted(filter_options_df["pickup_borough"].unique())
    pickup_borough = st.sidebar.selectbox(
        "Select Pickup Borough:",
        options=pickup_boroughs,
        index=0,
    )

    # Filter options based on selected pickup borough
    borough_options = filter_options_df[filter_options_df["pickup_borough"] == pickup_borough]

    all_years = sorted(borough_options["trip_year"].unique())
    selected_years = st.sidebar.multiselect("Select Year(s):", options=all_years, default=all_years)

    all_months = sorted(borough_options["trip_month"].unique())
    selected_months = st.sidebar.multiselect(
        "Select Month(s):", options=all_months, default=all_months
    )

    st.sidebar.markdown("---")  # Visual separator

    # --- NEW TOGGLE LOGIC ---
    all_dropoff_boroughs = sorted(borough_options["dropoff_borough"].unique())
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

    # Now load only the filtered data based on user selections
    filtered_df = load_filtered_kpi_data(
        pickup_borough=pickup_borough,
        years=selected_years if selected_years else None,
        months=selected_months if selected_months else None,
        dropoff_boroughs=selected_dropoff_boroughs if selected_dropoff_boroughs else None,
    )

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
    st.warning(
        "Unable to load filter options from Redshift. Please check the connection and data availability."
    )
