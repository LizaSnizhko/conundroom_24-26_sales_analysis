# Conundroom Escape Rooms Sales Analysis

<img width="500" height="158" alt="conundroom_color_logo" src="https://github.com/user-attachments/assets/43c73426-7548-44a4-8b02-768761f8a522" />

## Project Overview

This project analyzes sales and booking data for Conundroom Escape Rooms from July 1, 2024 through June 30, 2026. The goal is to explore booking trends, revenue, customer behavior, and business performance across all three locations using SQL and Tableau.

The analysis uses data exported from the Bookeo booking platform (online sales) and Square (on-site sales) for three Conundroom locations. The datasets contain booking and customer information, as well as payments, for 2 years.

## Tools
* PostgreSQL
* Tableau
* Excel (+Power Query)


## Limitations I've discovered so far:

* Walk-in booking counts cannot be separated from on-site player add-ons in the current data. On-site figures reflect revenue and participant counts only, not distinct bookings, and wherever total bookings are visualized, that number refers to online bookings only.
* It is not possible to identify the location where each on-site transaction was completed. The data only includes a device_id column. Some values appear frequently enough to be mapped to a location based on the escape room the transaction was for, but 17.06% are null, and 3% correspond to devices used only a handful of times.
* The net_sales data in the "on_site_sales" dataset cannot be treated as 100% accurate, since staff occasionally make entry errors, such as omitting tax or card fees, misclassifying items sold, or using a custom amount instead of selecting the correct item. These custom-amount entries don't correspond to any specific product, making them difficult or impossible to classify. Some transactions were manually entered or corrected via SQL.
* As of now, it is not possible to determine how many leads converted into inquiries by inquiry type for 2024–Q1 2025, since that data was not consolidated and was spread across Google Analytics, Zendesk, email, and disconnected phone lines.
