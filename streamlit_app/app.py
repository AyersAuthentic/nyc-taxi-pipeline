import altair as alt
import pandas as pd
import psycopg2
import streamlit as st

st.set_page_config(page_title="NYC Taxi Trip Analysis", page_icon="🚕", layout="wide")


@st.cache_resource
def get_redshift_connection():
    """Establishes a connection to the Redshift database."""
    try:
        conn = psycopg2.connect(
            host=st.secrets["redshift"]["host"],
            dbname=st.secrets["redshift"]["dbname"],
            user=st.secrets["redshift"]["user"],
            password=st.secrets["redshift"]["password"],
            port=st.secrets["redshift"]["port"],
        )
        st.success("Connected to Redshift successfully!")
        return conn
    except Exception as e:
        st.error(f"Error connecting to Redshift: {e}")
        return None


@st.cache_data
def load_kpi_data():
    """Fetches the KPI data from the Redshift data mart."""
    conn = get_redshift_connection()
    if conn:
        try:
            query = 'SELECT * FROM "marts"."kpi_trip_duration_by_weather"'
            df = pd.read_sql_query(query, conn)
            return df
        except Exception as e:
            st.error(f"Error loading data: {e}")
            return pd.DataFrame()  # Return empty dataframe on error
    return pd.DataFrame()


st.title("🚕 NYC Taxi Dashboard: Trip Duration Analysis")
st.markdown("Analyzing the impact of weather on taxi trip durations across different NYC boroughs.")

data_load_state = st.text("Loading data...")
df = load_kpi_data()
data_load_state.text("Data loaded successfully! ✅")
st.sidebar.header("Filter Your Analysis")


pickup_borough = st.sidebar.selectbox(
    "Select Pickup Borough:",
    options=df["pickup_borough"].unique(),
    index=0,
)

filtered_df = df[df["pickup_borough"] == pickup_borough]


st.header(f"Median Trip Duration from {pickup_borough}")
st.markdown(
    "This chart shows the median trip duration in minutes,\n"
    "grouped by dropoff borough and rain intensity."
)

if not filtered_df.empty:
    chart = (
        alt.Chart(filtered_df)
        .mark_bar()
        .encode(
            # X-axis: Group by dropoff_borough
            x=alt.X("dropoff_borough:N", title="Dropoff Borough", sort=None),
            # Y-axis: The value we are measuring
            y=alt.Y("median_trip_duration:Q", title="Median Trip Duration (Minutes)"),
            # Color defines the different series within each group
            color=alt.Color("precipitation_category:N", title="Precipitation"),
            # THIS IS THE FIX: Offset bars on the X-axis by the color category
            xOffset="precipitation_category:N",
            # Tooltip for interactivity
            tooltip=[
                "dropoff_borough",
                "precipitation_category",
                alt.Tooltip("median_trip_duration:Q", format=".1f"),
            ],
        )
    )
    st.altair_chart(chart, use_container_width=True, theme="streamlit")
else:
    st.warning("No data available for the selected filters.")

with st.expander("Show Raw Data Table"):
    st.dataframe(filtered_df)
