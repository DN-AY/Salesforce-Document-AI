---
title: Salesforce Document AI Guide
social:
  cards_layout_options:
    title: Documentation that simply works
hide:
    - navigation
---

# Foreword
This guide is made for any Salesforce developers who wants to use Document AI API along with Lightning Web Component (LWC) and Apex classes but is unable to due to the lack of well-documented resources.
As of current version, there are largely two ways to utilize Document AI.

## First Method 
One way to use Document AI is to process documents defined in "User-Defined Metadata Object" (UDMO) in Data Cloud, with extracted data saved in "Data Layer Objects (DLOs) based on a "schema". This document will explain what a "schema" is.

## Second Method
The second method is to call the Document AI API methods provided under Salesforce's "Data Cloud Connect API". 
This guide will only focus on the second method. Unlike relying on Data Cloud UDMO/DLOs, use of API endpoint allows not only the customization of data extraction process but also customization of an accessible and easy-to-understand UI that is catered to your client or your fellow administrators and developers. 

## What is "Schema"?
In Salesforce Document AI, "schema" refers to a set of field names and descriptions. A user will create a "schema" based on the type of file they want to extract data from.