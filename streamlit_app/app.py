import pandas as pd
import plotly.express as px
import psycopg2
import streamlit as st

st.set_page_config(page_title="NYC Taxi Trip Analysis", page_icon="🚕", layout="wide")


@st.cache_resource
def get_redshift_connection():
    try:
        conn = psycopg2.connect(**st.secrets["redshift"])
        st.success("Connected to Redshift successfully!")
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
            return df
        except Exception as e:
            st.error(f"Error loading data: {e}")
            return pd.DataFrame()
    return pd.DataFrame()


st.title("🚕 NYC Taxi Dashboard: Trip Duration Analysis")
st.markdown("Analyzing the impact of weather on taxi trip durations across different NYC boroughs.")

data_load_state = st.text("Loading data...")
df = load_kpi_data()
data_load_state.text("Data loaded successfully! ✅")

st.sidebar.header("Filter Your Analysis")
pickup_borough = st.sidebar.selectbox(
    "Select Pickup Borough:",
    options=sorted(df["pickup_borough"].unique()),
    index=0,
)

filtered_df = df[df["pickup_borough"] == pickup_borough].copy()

if not filtered_df.empty:
    st.subheader(f"Summary for {pickup_borough}")

    total_routes_analyzed = len(filtered_df)
    overall_median_duration = filtered_df["median_trip_duration"].mean()
    busiest_route_row = filtered_df.loc[filtered_df["median_trip_duration"].idxmax()]
    busiest_dropoff = busiest_route_row["dropoff_borough"]

    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric(label="Overall Median Duration", value=f"{overall_median_duration:.1f} min")
    with col2:
        st.metric(label="Routes Analyzed", value=f"{total_routes_analyzed}")
    with col3:
        st.metric(label="Longest Median Trip To", value=busiest_dropoff)
    st.markdown("---")

st.header(f"Median Trip Duration from {pickup_borough}")
st.markdown(
    "This chart shows the median trip duration in minutes, "
    "grouped by dropoff borough and rain intensity."
)

if not filtered_df.empty:
    category_order = ["No Rain", "Light Rain", "Moderate Rain", "Heavy Rain"]
    filtered_df["precipitation_category"] = pd.Categorical(
        filtered_df["precipitation_category"], categories=category_order, ordered=True
    )
    filtered_df = filtered_df.sort_values("precipitation_category")

    fig = px.bar(
        filtered_df,
        x="dropoff_borough",
        y="median_trip_duration",
        color="precipitation_category",
        barmode="group",
        labels={
            "dropoff_borough": "Dropoff Borough",
            "median_trip_duration": "Median Trip Duration (Minutes)",
            "precipitation_category": "Precipitation",
        },
        text_auto=".1f",
        color_discrete_map={
            "No Rain": "#1f77b4",
            "Light Rain": "#ff7f0e",
            "Moderate Rain": "#2ca02c",
            "Heavy Rain": "#d62728",
        },
    )

    fig.update_layout(
        title_x=0.5,
        legend_title_text="Precipitation",
        plot_bgcolor="rgba(0,0,0,0)",
        paper_bgcolor="rgba(0,0,0,0)",
        font=dict(color="white"),
        yaxis=dict(gridcolor="rgba(255, 255, 255, 0.2)"),
        xaxis_title=None,
    )

    fig.update_traces(textfont_size=12, textangle=0, textposition="outside", cliponaxis=False)

    st.plotly_chart(fig, use_container_width=True)
else:
    st.warning("No data available for the selected filters.")

with st.expander("Show Raw Data Table"):
    st.dataframe(filtered_df)
