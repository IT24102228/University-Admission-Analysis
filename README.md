# NEXTGENEDU AI — University Admission Analysis

**Statistical modelling and an interactive R Shiny application for graduate admissions decision support.**

# APP IS LIVE : https://nextgenedu.shinyapps.io/nextgenedu/

NEXTGENEDU AI combines exploratory analysis, statistical inference, regression modelling and a Naive Bayes classifier with an applicant ranking and shortlisting dashboard. It demonstrates how statistical evidence can support admissions officers when reviewing applications and allocating interview capacity.

> **Academic prototype:** predictions estimate the dataset's recorded `Chance_of_Admit` values. They are not guaranteed admission outcomes, measures of applicant worth, or a replacement for human review.

## Contents

- [Project overview](#project-overview)
- [Team](#team)
- [Application features](#application-features)
- [Repository layout](#repository-layout)
- [Dataset and input format](#dataset-and-input-format)
- [Statistical methodology](#statistical-methodology)
- [Model results](#model-results)
- [PCA prediction workflow](#pca-prediction-workflow)
- [Ranking and shortlisting](#ranking-and-shortlisting)
- [Run locally](#run-locally)
- [Deploy to shinyappsio](#deploy-to-shinyappsio)
- [Reproducibility and validation](#reproducibility-and-validation)
- [Troubleshooting](#troubleshooting)
- [Responsible use and limitations](#responsible-use-and-limitations)
- [Future development](#future-development)
- [Selected references](#selected-references)

## Project overview

Graduate admissions teams evaluate multiple indicators, including academic results, test scores, supporting-document ratings and research experience. Manual screening can create heavy workloads and inconsistent prioritisation.

This project investigates three practical questions:

1. Which applicant characteristics are associated with the recorded admission chance?
2. Which statistical models estimate that value most effectively on held-out data?
3. How can a dashboard turn those estimates into a transparent, configurable interview shortlist?

The consultancy scenario concerns a university graduate admissions office. The public dataset is a proxy for institutional records; this repository does not establish that the system has been deployed in a real admissions office.

### Consultancy scope

| Task | Focus |
| --- | --- |
| 1 | Industry problem, stakeholders and business objectives |
| 2 | Critical review of relevant research |
| 3 | Data quality, descriptive statistics and visual exploration |
| 4 | Hypothesis testing and interpretation |
| 5 | Regression model development and comparison |
| 6 | Critical evaluation of CRD and RCBD experimental designs |
| 7 | Principal component analysis and its predictive use |
| 8 | Naive Bayes and critical discussion of Bayesian methods |
| 9 | Potential use of time series forecasting for application volumes |
| 10 | NEXTGENEDU AI innovation proposal |
| 11 | Industry expert consultation and validation documentation |
| 12 | Strategic, operational and ethical recommendations |

Experimental designs, Bayesian regression and operational forecasting are discussed as extensions. They should not be interpreted as implemented dashboard features. Any simulated forecasting example is illustrative, not evidence from real historical application volumes. Expert consultation evidence belongs in the final consultancy deliverables; the supplied report draft contains unfinished expert-validation sections.

## Team

| Student ID | Student name |
| --- | --- |
| IT24102228 | Welgama W. N. Y |
| IT24100001 | Rifshadh M.R.M. |
| IT24102060 | Umar Z.M.Z |
| IT24101461 | Hannadige A. K. L. F. |

## Application features

| Feature | What it does |
| --- | --- |
| Individual prediction | Estimates an applicant's admission-chance value with PCA regression |
| Student profile | Displays entered information and visual comparisons |
| Naive Bayes classification | Estimates membership of a higher or lower admission-chance group |
| Evaluation display | Presents recorded held-out classification metrics and a confusion matrix |
| Bulk CSV upload | Loads applicant records and checks the expected inputs |
| Model ranking | Orders applicants by PCA regression prediction |
| Custom weighted ranking | Combines scaled applicant features using adjustable weights |
| Combined ranking | Blends the prediction score and custom weighted score |
| Percentage or seat selection | Selects a requested top percentage or number of applicants |
| Selection status | Indicates whether an applicant is inside or outside the selected range |
| Applicant radar profile | Compares an applicant with the applicant at the shortlist cutoff |
| CSV reports | Downloads the interview shortlist or full selection report with settings |

The bulk workflow has five stages: upload, choose a ranking method, configure settings, set capacity, and review results. The primary results table shows selected applicants; a separate full-results view supports inspection of the entire uploaded dataset.

## Repository layout

Paths below describe the deployment-ready layout. `app/data/` contains the dataset copy used by the hosted application.

| Path | Purpose |
| --- | --- |
| `README.md` | Project overview and usage instructions |
| `app/app.R` | Shiny interface, PCA regression, ranking, selection and exports |
| `app/naive_bayes_model.R` | Naive Bayes training, prediction helper and recorded evaluation values |
| `app/data/Graduate_Admissions.csv` | Dataset bundled with the deployed app |
| `app/run.txt` | Existing local run notes |
| `data/Graduate_Admissions.csv` | Project analysis dataset |
| `notebooks/` | Analysis notebooks and modelling work |
| `.gitignore` | Files excluded from version control |

Keep the two dataset copies consistent when updating the source data. Runtime logs are not required for deployment.

## Dataset and input format

The project analysis uses **400 observations**, seven predictors, a numeric target and a serial identifier. The analysis reports no missing values in the source dataset. Future inputs must still be validated.

### Data dictionary

Use the following cleaned column names for the application:

| Column | Meaning | Application scoring range |
| --- | --- | --- |
| `GRE_Score` | Graduate Record Examination score | 130–340 |
| `TOEFL_Score` | English proficiency score | 0–120 |
| `University_Rating` | Undergraduate university rating | 1–5 |
| `SOP` | Statement of Purpose rating | 1–5 |
| `LOR` | Letter of Recommendation rating | 1–5 |
| `CGPA` | Undergraduate cumulative grade point average | 0–10 |
| `Research` | Research experience indicator | 0 = no, 1 = yes |
| `Chance_of_Admit` | Recorded admission-chance target | 0–1; training only |

These are application-supported scoring ranges, not the observed minimum and maximum of every column in the dataset. The serial number is an identifier, not a predictor.

### Bulk upload example

Bulk prediction requires the seven predictor columns; new applicants do not need a known `Chance_of_Admit`. Optional `Student_ID` and `Student_Name` columns help identify applicants in the profile selector.

```csv
Student_ID,Student_Name,GRE_Score,TOEFL_Score,University_Rating,SOP,LOR,CGPA,Research
DEMO001,Sample Applicant A,325,112,4,4.0,4.5,8.90,1
DEMO002,Sample Applicant B,310,102,3,3.5,3.0,8.10,0
DEMO003,Sample Applicant C,332,116,5,4.5,4.5,9.30,1
```

These rows are fictional examples. Use numeric feature values, retain the exact header spelling, and resolve missing or out-of-range values before selection.

## Statistical methodology

### Exploratory analysis and inference

The analysis examines distributions, summary statistics and relationships among applicant characteristics. Three principal inferential comparisons are:

| Method | Variables | Interpretation |
| --- | --- | --- |
| Welch two-sample t-test | Research groups and `Chance_of_Admit` | Tests whether the two group means differ |
| Pearson correlation | CGPA and `Chance_of_Admit` | Measures the strength and direction of a linear association |
| One-way ANOVA | University Rating groups and `Chance_of_Admit` | Tests whether at least one group mean differs |

Reported findings indicate higher average recorded admission chance among applicants with research experience, a strong positive CGPA association, and differences among university-rating groups. These are observational associations. They do not establish that changing a feature causes admission success. ANOVA alone does not identify which pairs of groups differ.

### Regression comparison

Six regression approaches were compared using the same **320 training / 80 test** split:

- Multiple linear regression: original-feature baseline.
- Backward selection: a reduced regression selected using AIC.
- Ridge regression: L2 coefficient shrinkage.
- LASSO regression: L1 shrinkage, which can set coefficients to zero.
- Elastic net: a combination of L1 and L2 penalties.
- PCA regression: regression on retained principal components plus Research.

Lower **MAE** and **RMSE** are better. Higher test **R²** is better. R² is explained variation relative to a mean-based reference, not classification accuracy.

## Model results

### Regression performance on 80 held-out observations

| Model | MAE | RMSE | Test R² |
| --- | ---: | ---: | ---: |
| Multiple linear regression | 0.0470 | 0.0654 | 0.7863 |
| Backward selection | 0.0465 | 0.0650 | 0.7889 |
| Ridge regression | **0.0441** | 0.0618 | 0.8091 |
| LASSO regression | 0.0470 | 0.0653 | 0.7874 |
| Elastic net | 0.0462 | 0.0644 | 0.7930 |
| PCA regression | 0.0456 | **0.0613** | **0.8126** |

**The Shiny application implements PCA regression.** It achieved the lowest test RMSE and highest test R² in this comparison. RMSE gives larger errors greater influence, which is relevant when substantial prediction errors can affect applicant ranking.

Ridge achieved the lowest MAE and remains a useful benchmark with coefficients expressed against original predictors. The consultancy report discusses Ridge as an operational benchmark where interpretability is a priority. This is distinct from the PCA model implemented in the current app.

The performance gap is small; one held-out split does not establish that PCA will consistently outperform Ridge in another intake or institution.

### Naive Bayes classification

The classification label is derived from the recorded target:

- **Class 1:** `Chance_of_Admit >= 0.75`.
- **Class 0:** `Chance_of_Admit < 0.75`.

| Actual class | Predicted 0 | Predicted 1 |
| --- | ---: | ---: |
| 0 | 44 | 7 |
| 1 | 4 | 25 |

| Metric | Value |
| --- | ---: |
| Accuracy | 86.25% |
| Precision | 78.13% |
| Recall | 86.21% |
| Specificity | 86.27% |
| F1 score | 81.97% |

The classifier correctly labelled **69 of 80** test observations. Its posterior probability concerns membership of the derived class; it is not the same quantity as the PCA regression prediction. Classification accuracy and regression R² must not be compared as interchangeable percentages.

The `0.75` label threshold is separate from the percentage of applicants selected for interview. Changing it requires retraining and reevaluation.

## PCA prediction workflow

1. Take GRE, TOEFL, University Rating, SOP, LOR and CGPA.
2. Standardize the six features with the fitted centering and scaling values.
3. Project them using the fitted PCA transformation.
4. Retain PC1 and PC2.
5. Combine PC1, PC2 and the separate Research indicator in a linear regression.
6. Use the fitted model to predict the recorded admission-chance target.

Conceptually:

```text
Predicted Chance of Admit = intercept + b1 × PC1 + b2 × PC2 + b3 × Research
```

Research is kept separately to preserve its binary interpretation. This is a modelling choice; PCA is not inherently unable to process binary variables. PCA combines original features rather than simply selecting two of them.

The exploratory full-data PCA retained approximately **85.57%** of the six score features' variation in its first two components. The training-only PCA used for evaluation retained approximately **84.75%**. Neither number is prediction accuracy. Principal components are uncorrelated on the fitted data, not necessarily statistically independent.

For held-out evaluation, fit preprocessing and PCA on training records only and apply those fitted transformations to test records. The app currently refits its PCA, regression and Naive Bayes models on the bundled dataset when it starts; the displayed evaluation figures are recorded notebook results, not fresh validation of each startup fit.

## Ranking and shortlisting

### Ranking methods

| Method | Calculation |
| --- | --- |
| Model prediction | Rank by PCA regression prediction |
| Custom weighted score | Weighted average of the seven scaled features |
| Combined score | Blend model prediction, expressed on a 0–100 scale, with the custom weighted score |

For each feature, the weighted ranking uses the fixed ranges in the data dictionary:

```text
Scaled feature = 100 × (value − lower bound) / (upper bound − lower bound)
Effective weight = entered weight / sum of all entered weights
Weighted score = sum(effective weight × scaled feature)
Combined score = model share × (100 × prediction)
               + (1 − model share) × weighted score
```

The default combined setting is **60% model / 40% weighted score**. Users can adjust it. Feature weights must be non-negative and at least one must be positive; a zero weight excludes a feature from the custom weighted score. It does not remove that feature from the trained PCA model.

**A weighted or combined score is a prioritisation score, not an admission probability.** Changing dashboard weights does not retrain the statistical model.

### Capacity and selection status

Percentage selection rounds up:

```text
Selected count = ceiling(total applicants × selected percentage / 100)
```

For example, 20% of 10 applicants selects **2**, while 20% of 11 selects **3**. Seat-based selection uses the requested available capacity, subject to the number of applicants.

Applicants within the cutoff rank are inside the selected range. Applicants after the cutoff are outside it. Being outside the shortlist is not a final rejection decision.

Ranking uses full-precision scores before display rounding. Exact weighted-score ties use model rank as a tie-breaker. The radar chart compares feature profiles with the cutoff applicant; radar area itself does not determine selection.

## Run locally

### Requirements

- R installed on your computer; the demonstrated environment uses R 4.5.x.
- VS Code with an R extension, or RStudio.
- R packages `shiny` and `e1071`.
- `rsconnect` for deployment only.

The following commands assume the working directory is the repository root, containing `app/` and `data/`.

### 1. Install packages in an R console

```r
install.packages(c("shiny", "e1071", "rsconnect"),
                 repos = "https://cloud.r-project.org")
```

In VS Code, press **Ctrl + Shift + P**, choose **R: Create R terminal**, and enter R commands in that terminal. Do not enter the command-palette label into PowerShell.

### 2. Prepare the deployment dataset

```r
dir.create("app/data", showWarnings = FALSE)
file.copy("data/Graduate_Admissions.csv",
          "app/data/Graduate_Admissions.csv",
          overwrite = TRUE)
```

In `app/app.R`, the dataset path must be:

```r
data_path <- file.path("data", "Graduate_Admissions.csv")
```

The model helper remains beside `app.R` and is loaded as `naive_bayes_model.R`.

### 3. Launch the app

```r
shiny::runApp("app", launch.browser = TRUE)
```

Use the browser address printed by R. The port may vary. Stop the local app with **Ctrl + C** in its terminal.

### 4. Try the workflow

1. Enter an individual applicant's information and generate a prediction.
2. Inspect the profile and Naive Bayes output.
3. Upload a CSV in **Bulk Student Selection**.
4. Choose a ranking method and adjust its settings.
5. Select a top percentage or seat count.
6. Click **Rank and Select Applicants**.
7. Review selected records, full results and the cutoff comparison.
8. Download the shortlist or full report.

## Deploy to shinyapps.io

A successful deployment has not been established by this README. Add a live-demo link only after deployment completes and the hosted app has been checked.

1. Create a shinyapps.io account.
2. Copy the account authorization command from its dashboard.
3. Run it privately in an R console; never save tokens or secrets in source files, screenshots or commits.
4. Confirm the configured account with `rsconnect::accounts()`.
5. Test the app locally, then stop the local session.
6. From the repository root, deploy the required files:

```r
rsconnect::deployApp(
  appDir = "app",
  appFiles = c(
    "app.R",
    "naive_bayes_model.R",
    "data/Graduate_Admissions.csv"
  ),
  appName = "nextgenedu",
  account = "nextgenedu",
  server = "shinyapps.io"
)
```

Use your own account name if deploying a fork. Once deployment succeeds, open the URL returned by the command and test predictions, uploads and downloads. Hosting plan limits should be checked on the provider's website.

To update the hosted app, save and test your changes, then run the deployment command again. **Pushing to GitHub does not automatically update shinyapps.io in this setup.**

## Reproducibility and validation

- The reported regression comparison uses a common 80/20 split of 400 records.
- Preserve the analysis notebook's random seed, preprocessing choices and train/test indices when reproducing results.
- Fit scaling, PCA and any feature selection on training data only.
- Select regularization settings using training data; reserve the test set for evaluation.
- The app trains at startup and does not rerun the six-model comparison.
- Classification metrics in `naive_bayes_model.R` are stored reference values. If the data, feature types, labels or model implementation change, rerun evaluation before updating those values.
- Keep Research encoding consistent between notebook evaluation and deployment. The supplied app helper currently passes numeric 0/1 Research to `e1071`; treating it as a factor changes its class-conditional model and requires reevaluation.

Before sharing a release, check individual prediction, all three ranking methods, percentage and seat selection, CSV validation, cutoff profiles, and both report downloads. For a 10-row upload with 20% selection, verify that the shortlist contains exactly two records.

## Troubleshooting

| Symptom | Suggested check |
| --- | --- |
| `Cannot find drive ... R` in PowerShell | Open the VS Code Command Palette and select an R terminal; do not type `R: Create R terminal` into PowerShell |
| Missing dataset | Confirm `app/data/Graduate_Admissions.csv` exists and `app.R` uses the relative `data` path |
| Missing required columns | Match the exact column names in the data dictionary |
| Naive Bayes unavailable | Confirm `e1071` is installed and `naive_bayes_model.R` is beside `app.R` |
| Full dataset visible after selecting 20% | Check whether you are viewing full results rather than the selected-applicant table |
| Weight changes do not affect results | Apply the settings using **Rank and Select Applicants** |
| Works locally but fails after hosting | Check bundled files, filename capitalization, relative paths and hosting logs |
| Hosted version looks unchanged | Save changes and redeploy; a GitHub push alone is insufficient |
| Authentication fails | Reauthorize using a valid private token; revoke any exposed credentials |

## Responsible use and limitations

- **Target meaning:** the outcome is a recorded estimated chance, not a verified admitted/rejected decision or later academic success.
- **Small sample:** results come from 400 records and one reported held-out evaluation.
- **Generalisation:** local validation is needed before use in another institution, programme or admission cycle.
- **Interpretability:** PCA components combine features and are less direct to explain than original-feature coefficients.
- **Naive Bayes assumptions:** correlated academic features can violate conditional independence and affect probability calibration.
- **Fairness:** University Rating, test scores and document ratings can reflect differences in opportunity. Predictive performance does not establish fairness.
- **Uncertainty:** a point prediction is not a guarantee. A model-specific confidence or prediction interval is not an implemented feature of the current workflow.
- **Privacy:** use synthetic or appropriately de-identified data in public demonstrations. Do not commit private applicant information or deployment credentials.
- **Human oversight:** officers should review context, borderline cases and any recommendation before a final decision.

This prototype does not establish production authentication, durable decision storage, an audit trail, fairness certification or institutional integration.

## Future development

- Validate on institution-specific records and actual admission outcomes.
- Repeat model comparisons using robust resampling and external validation.
- Assess probability calibration and uncertainty communication.
- Add subgroup performance and fairness monitoring where appropriate data are available.
- Explore Bayesian regression and cost-sensitive decision thresholds.
- Collect dated application volumes before operational time series forecasting.
- Evaluate recruitment or support interventions using suitable CRD/RCBD designs.
- Add authenticated access, secure storage and documented officer overrides.
- Pilot with admissions staff and record how expert feedback changes the system.

## Selected references

The following references are drawn from the accompanying consultancy report. The full literature review and consultation evidence should be retained with the academic submission.

- Hoerl, A. E., & Kennard, R. W. (1970). Ridge regression: Biased estimation for nonorthogonal problems. *Technometrics, 12*(1), 55–67. [DOI](https://doi.org/10.1080/00401706.1970.10488634)
- Tibshirani, R. (1996). Regression shrinkage and selection via the lasso. *Journal of the Royal Statistical Society: Series B, 58*(1), 267–288. [DOI](https://doi.org/10.1111/j.2517-6161.1996.tb02080.x)
- Zou, H., & Hastie, T. (2005). Regularization and variable selection via the elastic net. *Journal of the Royal Statistical Society: Series B, 67*(2), 301–320. [DOI](https://doi.org/10.1111/j.1467-9868.2005.00503.x)
- Jolliffe, I. T., & Cadima, J. (2016). Principal component analysis: A review and recent developments. *Philosophical Transactions of the Royal Society A, 374*, 20150202. [DOI](https://doi.org/10.1098/rsta.2015.0202)
- Domingos, P., & Pazzani, M. (1997). On the optimality of the simple Bayesian classifier under zero-one loss. *Machine Learning, 29*, 103–130. [DOI](https://doi.org/10.1023/A:1007413511361)
- Baker, R. S., & Hawn, A. (2022). Algorithmic bias in education. *International Journal of Artificial Intelligence in Education, 32*, 1052–1092. [DOI](https://doi.org/10.1007/s40593-021-00285-9)
- Acharya, M. S., Armaan, A., & Antony, A. S. (2019). A comparison of regression models for prediction of graduate admissions. *2019 International Conference on Computational Intelligence in Data Science (ICCIDS)*, 1–5. Dataset-associated study cited by the project report.

## License and attribution

Consult the repository's license, if provided, before reusing its code. Dataset reuse is subject to the original source's terms. This README does not grant a new software or dataset license.
