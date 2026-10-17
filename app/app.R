library(shiny)

# ---------------------------------------------------------
# Load and prepare dataset
# ---------------------------------------------------------

data_path <- file.path("data", "Graduate_Admissions.csv")

dataset_error <- NULL
model_error <- NULL
nb_error <- NULL
admission_data <- NULL
pca_model <- NULL
pca_regression_model <- NULL
continuous_features <- c("GRE_Score", "TOEFL_Score", "University_Rating", "SOP", "LOR", "CGPA")
admission_data <- tryCatch({
  data <- read.csv(data_path)
  needed <- c(continuous_features, "Research", "Chance_of_Admit")
  if (!all(needed %in% names(data))) stop("The project dataset is missing required columns.")
  if (nrow(data) == 0) stop("The project dataset is empty.")
  if (!all(vapply(data[, needed], function(x) is.numeric(x) && all(is.finite(x)), logical(1)))) {
    stop("The project dataset contains missing or non-numeric feature values.")
  }
  data$Admission_Class <- factor(ifelse(data$Chance_of_Admit >= .75, "High Admission", "Lower Admission"),
                                levels = c("Lower Admission", "High Admission"))
  data
}, error = function(e) { dataset_error <<- conditionMessage(e); NULL })
if (!is.null(admission_data)) {
  tryCatch({
    pca_model <- prcomp(admission_data[, continuous_features], center = TRUE, scale. = TRUE)
    pca_training_data <- data.frame(Chance_of_Admit = admission_data$Chance_of_Admit,
      PC1 = pca_model$x[, 1], PC2 = pca_model$x[, 2], Research = admission_data$Research)
    pca_regression_model <- lm(Chance_of_Admit ~ PC1 + PC2 + Research, data = pca_training_data)
  }, error = function(e) { model_error <<- conditionMessage(e) })
  tryCatch(source("naive_bayes_model.R", local = TRUE),
           error = function(e) { nb_error <<- conditionMessage(e) })
}

# ---------------------------------------------------------
# User interface
# ---------------------------------------------------------

ui <- fluidPage(
 tags$head(
    tags$style(HTML("
      body {
        background-color: #f4f7fb;
      }

      .title-box {
        background: linear-gradient(135deg, #173b67, #2878b5);
        color: white;
        padding: 25px;
        border-radius: 10px;
        margin-bottom: 20px;
      }

      .result-box {
        background-color: white;
        border-left: 6px solid #2878b5;
        padding: 20px;
        border-radius: 8px;
        margin-top: 15px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      }

      .btn-primary {
        width: 100%;
        background-color: #2878b5;
        font-weight: bold;
      }
    "))
  , tags$style(HTML(".shiny-output-error-validation {color:#a12622;} .shiny-plot-output.recalculating {position:relative; opacity:.6;} .shiny-plot-output.recalculating:after {content:'Loading chart...';position:absolute;top:45%;left:35%;color:#173b67;} .table {font-size:14px;} .tab-content {padding-top:18px;} .step-track {padding:14px;background:#e6edf5;border-radius:8px;margin-bottom:18px;} .shiny-html-output {overflow-x:auto;} #bulk_wizard_error {color:#a12622;margin:10px 0;}"))),
 div(class = "title-box", h1("University Admission Analysis"), p("Applicant prediction and selection support")),
 uiOutput("app_status"),
 tabsetPanel(id = "main_tabs",
 tabPanel("Individual Student Prediction", sidebarLayout(sidebarPanel(

      h3("Student Information"),

      numericInput(
        "gre",
        "GRE Score",
        value = 320,
        min = 260,
        max = 340
      ),

      numericInput(
        "toefl",
        "TOEFL Score",
        value = 110,
        min = 0,
        max = 120
      ),

      sliderInput(
        "university",
        "University Rating",
        min = 1,
        max = 5,
        value = 3,
        step = 1
      ),

      sliderInput(
        "sop",
        "Statement of Purpose Strength",
        min = 1,
        max = 5,
        value = 3.5,
        step = 0.5
      ),

      sliderInput(
        "lor",
        "Letter of Recommendation Strength",
        min = 1,
        max = 5,
        value = 3.5,
        step = 0.5
      ),

      numericInput(
        "cgpa",
        "CGPA",
        value = 8.5,
        min = 0,
        max = 10,
        step = 0.01
      ),

      radioButtons(
        "research",
        "Research Experience",
        choices = c(
          "No" = 0,
          "Yes" = 1
        ),
        selected = 1,
        inline = TRUE
      ),

      actionButton(
        "predict",
        "Predict Admission",
        class = "btn-primary"
      )
    ), mainPanel(
 p("Enter student information and click Predict Admission to see the result."),
 conditionalPanel("input.predict > 0", 

          div(
            class = "result-box",
            h2("Predicted Admission Chance"),
            h1(textOutput("probability")),
            h3(textOutput("classification")),
            p(textOutput("interpretation"))
          ),

          plotOutput("probability_plot", height = "300px")
        )
 ))),
 tabPanel(
          "Student Profile",
          conditionalPanel("!input.predict", p("Create a prediction in Individual Student Prediction to view the student's profile.")),
          h3("Entered Student Information"),
          tableOutput("student_table"),
          p("Scores are shown as percentages of their maximum values, not percentiles or admission probabilities. Research: 100 means Yes; 0 means No."),
          conditionalPanel("input.predict > 0", plotOutput("profile_plot", height = "400px"))
        ),
 tabPanel(
          "Naive Bayes",
          conditionalPanel("!input.predict", p("Create a prediction in Individual Student Prediction to view the student's classification.")),

          div(
            class = "result-box",
            h2("Naive Bayes Classification"),
            h3(textOutput("nb_classification")),
            h4(textOutput("nb_probability")),
            p(
              "Naive Bayes classifies the student as having high or
               lower admission potential."
            )
          ),

          h3("Model Evaluation on 80 Test Students"),
          tableOutput("nb_metrics"),

          h3("Confusion Matrix"),
          tableOutput("nb_confusion")
        ),
 tabPanel("Dataset Visualizations", h2("University Admission Dataset Analysis"),
 p("These charts use the project's historical dataset. They do not require an individual prediction or a bulk CSV upload."),
 uiOutput("dataset_charts")),
 tabPanel("Bulk Student Selection",
 h3("Bulk Applicant Selection"),
 uiOutput("bulk_step_indicator"),
 textOutput("bulk_wizard_error"),
 conditionalPanel("output.bulk_step == 1",
   h4("1. Upload applicants"),
   uiOutput("bulk_upload_control"),
   actionButton("remove_bulk_file", "Remove CSV"),
   p("You can replace a file by uploading another CSV. Removing it clears this session's results; your original file stays on your computer."),
   uiOutput("bulk_upload_status"),
   tableOutput("bulk_preview"),
   actionButton("bulk_next_upload", "Next: ranking method", class = "btn-primary")
 ),
 conditionalPanel("output.bulk_step == 2",
   h4("2. Choose a ranking method"),
   radioButtons(
    "ranking_method",
    "Rank applicants using",
    choices = c("Model prediction" = "model", "Custom weighted score" = "weighted",
                "Combined score" = "combined"),
    selected = "weighted"
  ),
   actionButton("bulk_back_method", "Back"),
   actionButton("bulk_next_method", "Next: configure ranking", class = "btn-primary")
 ),
 conditionalPanel("output.bulk_step == 3",
   h4("3. Configure ranking"),
   conditionalPanel("input.ranking_method == 'model'", p("Model prediction uses the trained model. No feature weights are needed.")),
   conditionalPanel("input.ranking_method != 'model'",   h4("Applicant feature weights"),
  p("Weights are relative importance values. The system automatically converts their total to 100%. Set a weight to 0 to exclude that feature."),
  fluidRow(
    column(4,
      numericInput("weight_gre", "GRE weight", 35, min = 0, max = 100),
      numericInput("weight_toefl", "TOEFL weight", 5, min = 0, max = 100),
      numericInput("weight_cgpa", "CGPA weight", 30, min = 0, max = 100)
    ),
    column(4,
      numericInput("weight_sop", "SOP weight", 10, min = 0, max = 100),
      numericInput("weight_lor", "LOR weight", 10, min = 0, max = 100)
    ),
    column(4,
      numericInput("weight_university", "University Rating weight", 5, min = 0, max = 100),
      numericInput("weight_research", "Research weight", 5, min = 0, max = 100)
    )
  ),
  textOutput("bulk_weight_summary"),
  p("For the weighted score, features use comparable 0-100 scales: GRE 130-340; TOEFL 0-120; University Rating, SOP and LOR 1-5; CGPA 0-10; Research 0-1. Higher values score higher. Apply your settings using Rank and Select Applicants."),
  hr()),
   conditionalPanel("input.ranking_method == 'combined'",   sliderInput(
    "model_share", "Model contribution to combined score",
    min = 0, max = 100, value = 60, step = 1, post = "%"
  ),
  textOutput("bulk_combination_summary"),
  p("The remaining percentage uses the custom weighted score. The combined score is a ranking score for shortlisting, not an admission probability or model accuracy.")),
   actionButton("bulk_back_settings", "Back"),
   actionButton("bulk_next_settings", "Next: selection size", class = "btn-primary")
 ),
 conditionalPanel("output.bulk_step == 4",
   h4("4. Choose the shortlist size"),
     radioButtons(
    "selection_method",
    "Selection Method",
    choices = c(
      "Select top percentage" = "percentage",
      "Select by available seats" = "seats"
    ),
    selected = "percentage"
  ),

  conditionalPanel(
    condition = "input.selection_method == 'percentage'",

    sliderInput(
      "top_percentage",
      "Top percentage to select",
      min = 1,
      max = 100,
      value = 20,
      step = 1,
      post = "%"
    )
  ),

  conditionalPanel(
    condition = "input.selection_method == 'seats'",

    numericInput(
      "available_seats",
      "Number of available seats",
      value = 20,
      min = 1,
      step = 1
    )
  ),
   actionButton("bulk_back_selection", "Back"),
   actionButton("run_bulk_selection", "Rank and Select Applicants", class = "btn-primary")
 ),
 conditionalPanel("output.bulk_step == 5",
   actionButton("bulk_edit_settings", "Back: change selection settings"),
   actionButton("bulk_new_upload", "Back: upload or remove CSV"),
   h3("Selected Applicants"),
  textOutput("bulk_selection_summary"),
  downloadButton("download_interview_shortlist", "Download Interview Shortlist (CSV)"),
  downloadButton("download_selection_report", "Download Full Selection Report (CSV)"),
  p("Generate results before downloading. The interview shortlist includes selected applicants only; the full report includes every applicant and their selection status."),
  tableOutput("bulk_prediction_table"),
  tags$details(
    tags$summary("View all applicants and selection status"),
    tableOutput("bulk_all_applicants_table")
  ),
  hr(),
  h3("Individual Applicant Profile"),
  uiOutput("bulk_applicant_selector"),
  uiOutput("bulk_applicant_profile"),
  plotOutput("bulk_applicant_radar", height = "480px"),
  p("The radar chart compares this applicant with the applicant at the shortlist cutoff. Each feature is scaled from 0 to 100. A larger radar shape does not determine selection; the chosen ranking score and cutoff rank determine the decision.")
 )
),
 tabPanel(
          "Model Information",
          h3("PCA Regression Model"),
          p(
            "The six continuous admission predictors are standardized
             and combined into principal components."
          ),
          p(
            "PC1 and PC2 are used together with research experience
             to estimate the admission probability."
          ),
          tags$ul(
            tags$li("Notebook test R-squared: 0.8126"),
            tags$li("Notebook test MAE: 0.0456"),
            tags$li("Notebook test RMSE: 0.0613"),
            tags$li("PC1 and PC2 retained approximately 85.57% of variation")
          ),
          h3("Naive Bayes Model"),
          p(
            "The Naive Bayes model classifies whether the predicted
             admission potential is high or lower using a 75% threshold."
          )
        )
 )
)

# ---------------------------------------------------------
# Server logic
# ---------------------------------------------------------

server <- function(input, output, session) {


  wizard_step <- reactiveVal(1L)
  wizard_error <- reactiveVal("")
  current_upload <- reactiveVal(NULL)
  upload_generation <- reactiveVal(0L)
  output$bulk_step <- renderText(wizard_step())
  outputOptions(output, "bulk_step", suspendWhenHidden = FALSE)
  output$bulk_wizard_error <- renderText(wizard_error())
  output$bulk_step_indicator <- renderUI({
    labels <- c("Upload", "Ranking method", "Settings", "Selection size", "Results")
    div(class = "step-track", paste0("Step ", wizard_step(), " of 5: ", labels[wizard_step()]))
  })
  output$bulk_upload_control <- renderUI({
    upload_generation()
    fileInput("bulk_file", "Upload Applicant CSV", accept = ".csv")
  })
  observeEvent(input$bulk_file, {
    current_upload(input$bulk_file)
    wizard_step(1L)
    wizard_error("")
  }, ignoreNULL = TRUE)
  observeEvent(input$remove_bulk_file, {
    current_upload(NULL)
    upload_generation(isolate(upload_generation()) + 1L)
    wizard_step(1L)
    wizard_error("")
  })
  output$bulk_upload_status <- renderUI({
    file <- current_upload()
    if (is.null(file)) return(p("No CSV uploaded. Choose an applicant CSV to begin."))
    data <- bulk_data()
    p(paste0(file$name, " - ", nrow(data), " applicants ready. Preview: first 10 rows."))
  })
  advance <- function(check, destination) {
    tryCatch({ force(check); wizard_error(""); wizard_step(destination) },
      error = function(e) {
        msg <- conditionMessage(e)
        wizard_error(if (nzchar(msg)) msg else "Please upload a valid applicant CSV before continuing.")
      })
  }
  observeEvent(input$bulk_next_upload, { advance(bulk_data(), 2L) })
  observeEvent(input$bulk_next_method, { advance(req(input$ranking_method), 3L) })
  observeEvent(input$bulk_next_settings, {
    advance({
      if (input$ranking_method != "model") bulk_weights()
      if (input$ranking_method == "combined") bulk_model_share()
    }, 4L)
  })
  observeEvent(input$run_bulk_selection, { advance(bulk_selection(), 5L) })
  observeEvent(input$bulk_back_method, { wizard_step(1L); wizard_error("") })
  observeEvent(input$bulk_back_settings, { wizard_step(2L); wizard_error("") })
  observeEvent(input$bulk_back_selection, { wizard_step(3L); wizard_error("") })
  observeEvent(input$bulk_edit_settings, { wizard_step(4L); wizard_error("") })
  observeEvent(input$bulk_new_upload, { wizard_step(1L); wizard_error("") })
  output$app_status <- renderUI({
    errors <- c(dataset_error, model_error, nb_error)
    if (length(errors)) div(class = "alert alert-warning", paste(errors, collapse = " "))
  })
  output$dataset_charts <- renderUI({
    if (is.null(admission_data) || nrow(admission_data) == 0) {
      return(div(class = "alert alert-info", "No dataset available. Check ../data/Graduate_Admissions.csv and restart the app.",
                 if (!is.null(dataset_error)) p(dataset_error)))
    }
    tagList(fluidRow(

    column(
      width = 6,
      div(
        class = "result-box",
        plotOutput(
          "research_admission_plot",
          height = "350px"
        )
      )
    ),

    column(
      width = 6,
      div(
        class = "result-box",
        plotOutput(
          "university_admission_plot",
          height = "350px"
        )
      )
    )
  ),

  fluidRow(

    column(
      width = 6,
      div(
        class = "result-box",
        plotOutput(
          "gre_boxplot",
          height = "350px"
        )
      )
    ),

    column(
      width = 6,
      div(
        class = "result-box",
        plotOutput(
          "toefl_boxplot",
          height = "350px"
        )
      )
    )
  ),

  fluidRow(

    column(
      width = 6,
      div(
        class = "result-box",
        plotOutput(
          "cgpa_boxplot",
          height = "350px"
        )
      )
    ),

    column(
      width = 6,
      div(
        class = "result-box",
        plotOutput(
          "sop_lor_plot",
          height = "350px"
        )
      )
    )
  ))
  })

  required_bulk_columns <- c(continuous_features, "Research")

  bulk_data <- reactive({
    req(current_upload())

    # Catch file-reading errors only, so Shiny validation messages remain visible.
    data <- tryCatch(
      read.csv(current_upload()$datapath, stringsAsFactors = FALSE),
      error = function(e) NULL
    )

    validate(
      need(!is.null(data), "This CSV could not be read. Please upload a valid applicant CSV file.")
    )
    validate(
      need(nrow(data) > 0, "The uploaded CSV file is empty."),
      need(ncol(data) > 0, "No columns were found in the CSV file.")
    )

    missing_columns <- setdiff(required_bulk_columns, names(data))
    validate(
      need(
        length(missing_columns) == 0,
        paste0(
          "This CSV does not contain the required student features. ",
          "Please upload an applicant CSV file. Missing columns: ",
          paste(missing_columns, collapse = ", "), "."
        )
      )
    )

    for (column in required_bulk_columns) {
      data[[column]] <- suppressWarnings(as.numeric(data[[column]]))
    }
    validate(need(all(vapply(data[, required_bulk_columns, drop = FALSE],
      function(x) all(is.finite(x)), logical(1))),
      "Some student features are missing or are not valid numbers."),
      need(all(data$Research %in% c(0, 1)), "Research must be 0 (No) or 1 (Yes)."))
    lower <- c(130, 0, 1, 1, 1, 0, 0)
    upper <- c(340, 120, 5, 5, 5, 10, 1)
    valid <- vapply(seq_along(required_bulk_columns), function(i) {
      all(data[[required_bulk_columns[i]]] >= lower[i] & data[[required_bulk_columns[i]]] <= upper[i])
    }, logical(1))
    validate(need(all(valid), paste("Values outside supported ranges:",
                                  paste(required_bulk_columns[!valid], collapse = ", "))))
    data
  })

  output$bulk_preview <- renderTable({
    head(bulk_data(), 10)
  })

  bulk_prediction <- eventReactive(input$run_bulk_selection, {
    validate(need(!is.null(pca_regression_model), "Prediction model unavailable. Check the project dataset and restart."))
    data <- bulk_data()

    for (column in required_bulk_columns) {
      data[[column]] <- suppressWarnings(as.numeric(data[[column]]))
    }

    validate(
      need(
        all(vapply(data[, required_bulk_columns, drop = FALSE],
                   function(values) all(is.finite(values)), logical(1))),
        "Some student feature values are missing or are not valid numbers. Please correct the CSV and upload it again."
      ),
      need(
        all(data$Research %in% c(0, 1)),
        "Research must be 0 (No) or 1 (Yes) for every applicant."
      )
    )

    applicant_components <- predict(
      pca_model,
      newdata = data[, continuous_features, drop = FALSE]
    )

    model_input <- data.frame(
      PC1 = applicant_components[, "PC1"],
      PC2 = applicant_components[, "PC2"],
      Research = data$Research
    )

    predictions <- predict(pca_regression_model, newdata = model_input)
    predictions <- pmax(0, pmin(1, predictions))
    data$Predicted_Admission_Chance <- round(predictions * 100, 2)

    # Rank using full precision; exact ties keep their original CSV order.
    model_order <- order(-predictions, seq_along(predictions))
    data <- data[model_order, , drop = FALSE]
    data$Rank <- seq_len(nrow(data))
    data <- data[, c("Rank", setdiff(names(data), "Rank")), drop = FALSE]
    rownames(data) <- NULL
    # Retain full precision in the same order as the ranked applicants.
    attr(data, "model_predictions") <- predictions[model_order]
    attr(data, "upload_path") <- current_upload()$datapath
    data
  })

  bulk_weights <- reactive({
    weights <- c(
      GRE_Score = input$weight_gre,
      TOEFL_Score = input$weight_toefl,
      University_Rating = input$weight_university,
      SOP = input$weight_sop,
      LOR = input$weight_lor,
      CGPA = input$weight_cgpa,
      Research = input$weight_research
    )
    validate(need(
      length(weights) == 7 && all(is.finite(weights)) &&
        all(weights >= 0 & weights <= 100) && sum(weights) > 0,
      "Enter seven weights between 0 and 100, with at least one greater than zero."
    ))
    weights / sum(weights)
  })

  output$bulk_weight_summary <- renderText({
    weights <- bulk_weights()
    paste("Effective weights:", paste(
      paste0(names(weights), " ", sprintf("%.1f%%", weights * 100)),
      collapse = "; "
    ))
  })

  bulk_model_share <- reactive({
    share <- input$model_share
    validate(need(
      isTRUE(length(share) == 1 && is.finite(share) && share >= 0 && share <= 100),
      "Choose a model contribution between 0 and 100%."
    ))
    share / 100
  })

  output$bulk_combination_summary <- renderText({
    share <- bulk_model_share()
    paste0("Combined score = ", round(share * 100), "% model prediction + ",
           round((1 - share) * 100), "% custom weighted score.")
  })

  computed_selection <- eventReactive(input$run_bulk_selection, {
    current_data <- bulk_data()
    req(current_data)
    results <- bulk_prediction()
    # A new upload must be predicted before its shortlist can be shown.
    req(identical(attr(results, "upload_path"), current_upload()$datapath))
    model_predictions <- attr(results, "model_predictions")
    total <- nrow(results)

    weights <- if (input$ranking_method == "model") {
      setNames(c(.35, .05, .05, .10, .10, .30, .05), required_bulk_columns)
    } else bulk_weights()
    lower <- c(GRE_Score = 130, TOEFL_Score = 0, University_Rating = 1,
               SOP = 1, LOR = 1, CGPA = 0, Research = 0)
    upper <- c(GRE_Score = 340, TOEFL_Score = 120, University_Rating = 5,
               SOP = 5, LOR = 5, CGPA = 10, Research = 1)
    normalized <- as.matrix(results[, names(weights), drop = FALSE])
    invalid_columns <- names(weights)[vapply(names(weights), function(feature) {
      any(results[[feature]] < lower[feature] | results[[feature]] > upper[feature])
    }, logical(1))]
    validate(need(
      length(invalid_columns) == 0,
      paste0("Applicant values are outside the supported scoring ranges. Check: ",
             paste(invalid_columns, collapse = ", "), ".")
    ))
    normalized <- sweep(normalized, 2, lower[names(weights)], "-")
    normalized <- sweep(normalized, 2, upper[names(weights)] - lower[names(weights)], "/")
    weighted_scores <- as.numeric(normalized %*% weights) * 100
    results$Weighted_Score <- round(weighted_scores, 2)
    model_share <- if (input$ranking_method == "combined") bulk_model_share() else .60
    combined_scores <- model_share * model_predictions * 100 +
      (1 - model_share) * weighted_scores
    results$Combined_Score <- round(combined_scores, 2)

    if (identical(input$ranking_method, "combined")) {
      results <- results[order(-combined_scores, results$Rank), , drop = FALSE]
      ranking_label <- paste0("combined score (", round(model_share * 100),
                              "% model / ", round((1 - model_share) * 100),
                              "% weighted)")
      score_column <- "Combined_Score"
    } else if (identical(input$ranking_method, "weighted")) {
      # Model rank breaks exact weighted-score ties consistently.
      results <- results[order(-weighted_scores, results$Rank), , drop = FALSE]
      ranking_label <- "custom weighted score"
      score_column <- "Weighted_Score"
    } else {
      ranking_label <- "model prediction"
      score_column <- "Predicted_Admission_Chance"
    }
    results$Rank <- seq_len(total)
    rownames(results) <- NULL

    if (identical(input$selection_method, "percentage")) {
      percentage <- input$top_percentage
      validate(need(
        isTRUE(length(percentage) == 1 && is.finite(percentage) &&
                 percentage >= 1 && percentage <= 100),
        "Please choose a percentage between 1 and 100."
      ))
      selected_count <- ceiling(total * percentage / 100)
      criterion <- paste0("top ", percentage, "%")
    } else {
      seats <- input$available_seats
      validate(need(
        isTRUE(length(seats) == 1 && is.finite(seats) &&
                 seats >= 1 && seats == floor(seats)),
        "Please enter a positive whole number of available seats."
      ))
      selected_count <- min(total, seats)
      criterion <- paste0(seats, " available seats")
    }

    results$Selection_Status <- ifelse(
      results$Rank <= selected_count,
      "Inside selected range",
      "Outside selected range"
    )
    results$Decision <- ifelse(
      results$Rank <= selected_count,
      "Selected",
      "Not selected"
    )

    list(
      upload_path = current_upload()$datapath,
      applicants = head(results, selected_count),
      all_applicants = results,
      selected_count = selected_count,
      score_column = score_column,
      ranking_label = ranking_label,
      selection_method = input$selection_method,
      selection_value = if (identical(input$selection_method, "percentage")) percentage else seats,
      feature_weights = weights,
      model_share = model_share,
      summary = paste0("Selected ", selected_count, " of ", total,
                       " applicants (", criterion, "), ranked by ", ranking_label,
                       ". Cutoff rank: ", selected_count, ". Cutoff score: ",
                       sprintf("%.2f / 100", results[[score_column]][selected_count]),
                       ".")
    )
  })

  bulk_selection <- reactive({
    req(current_upload())
    selection <- computed_selection()
    req(identical(selection$upload_path, current_upload()$datapath))
    selection
  })

  output$bulk_selection_summary <- renderText({
    bulk_selection()$summary
  })

  output$bulk_prediction_table <- renderTable({
    bulk_selection()$applicants
  })

  output$bulk_all_applicants_table <- renderTable({
    bulk_selection()$all_applicants
  })

  bulk_download_data <- function(selection, shortlist = FALSE) {
    report <- if (shortlist) selection$applicants else selection$all_applicants
    report$Interview_Status <- ifelse(report$Decision == "Selected",
                                     "Shortlisted for interview", "Not shortlisted")
    report$Ranking_Method <- selection$ranking_label
    report$Selection_Method <- selection$selection_method
    report$Selection_Value <- selection$selection_value
    report$Total_Applicants <- nrow(selection$all_applicants)
    report$Selected_Count <- selection$selected_count
    report$Cutoff_Rank <- selection$selected_count
    report$Cutoff_Score <- selection$all_applicants[[selection$score_column]][selection$selected_count]
    report$Model_Contribution_Percent <- selection$model_share * 100
    report$Weighted_Contribution_Percent <- (1 - selection$model_share) * 100
    for (feature in names(selection$feature_weights)) {
      report[[paste0("Weight_", feature, "_Percent")]] <-
        selection$feature_weights[[feature]] * 100
    }
    report$Report_Generated_UTC <- format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")
    report
  }

  # Protect applicant-provided text when the CSV is opened in a spreadsheet.
  write_bulk_report <- function(report, file) {
    for (column in names(report)) {
      if (is.character(report[[column]])) {
        dangerous <- !is.na(report[[column]]) &
          grepl("^[[:space:]]*[=+@-]", report[[column]])
        report[[column]][dangerous] <- paste0("'", report[[column]][dangerous])
      }
    }
    write.csv(report, file, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  }

  output$download_interview_shortlist <- downloadHandler(
    filename = function() paste0("interview_shortlist_", Sys.Date(), ".csv"),
    contentType = "text/csv",
    content = function(file) {
      write_bulk_report(bulk_download_data(bulk_selection(), shortlist = TRUE), file)
    }
  )

  output$download_selection_report <- downloadHandler(
    filename = function() paste0("selection_report_", Sys.Date(), ".csv"),
    contentType = "text/csv",
    content = function(file) {
      write_bulk_report(bulk_download_data(bulk_selection()), file)
    }
  )

  output$bulk_applicant_selector <- renderUI({
    results <- bulk_selection()$all_applicants
    labels <- paste0("Rank ", results$Rank)
    if ("Student_ID" %in% names(results)) {
      labels <- paste(labels, results$Student_ID, sep = " | ")
    }
    if ("Student_Name" %in% names(results)) {
      labels <- paste(labels, results$Student_Name, sep = " | ")
    }
    selected_rank <- isolate(input$bulk_applicant_rank)
    if (is.null(selected_rank) || !selected_rank %in% as.character(results$Rank)) {
      selected_rank <- "1"
    }
    selectizeInput("bulk_applicant_rank", "Choose an applicant to inspect",
                choices = setNames(as.character(results$Rank), labels),
                selected = selected_rank, width = "100%",
                options = list(dropdownParent = "body", maxOptions = nrow(results)))
  })

  bulk_profile <- reactive({
    selection <- bulk_selection()
    req(input$bulk_applicant_rank)
    results <- selection$all_applicants
    student <- results[results$Rank == as.numeric(input$bulk_applicant_rank), , drop = FALSE]
    req(nrow(student) == 1)
    list(student = student,
         cutoff = results[selection$selected_count, , drop = FALSE],
         selection = selection)
  })

  output$bulk_applicant_profile <- renderUI({
    profile <- bulk_profile()
    student <- profile$student
    selection <- profile$selection
    tags$div(
      tags$p(tags$strong(paste0("Rank: ", student$Rank, " out of ",
                               nrow(selection$all_applicants)))),
      tags$p(paste0("Cutoff rank: ", selection$selected_count,
                    " | ", student$Selection_Status, " | ", student$Decision)),
      tags$p(paste0("Ranking method: ", selection$ranking_label,
                    " | Applicant score: ",
                    sprintf("%.2f / 100", student[[selection$score_column]]))),
      tags$p(paste0("Model prediction: ", sprintf("%.2f%%", student$Predicted_Admission_Chance),
                    " | Weighted score: ", sprintf("%.2f / 100", student$Weighted_Score),
                    " | Combined score: ", sprintf("%.2f / 100", student$Combined_Score)))
    )
  })

  output$bulk_applicant_radar <- renderPlot({
    profile <- bulk_profile()
    features <- c("GRE_Score", "TOEFL_Score", "University_Rating",
                  "SOP", "LOR", "CGPA", "Research")
    lower <- c(130, 0, 1, 1, 1, 0, 0)
    upper <- c(340, 120, 5, 5, 5, 10, 1)
    scale_profile <- function(row) {
      values <- as.numeric(unlist(row[, features, drop = FALSE], use.names = FALSE))
      (values - lower) / (upper - lower)
    }
    student_values <- scale_profile(profile$student)
    cutoff_values <- scale_profile(profile$cutoff)
    angles <- pi / 2 - (seq_along(features) - 1) * 2 * pi / length(features)
    closed <- c(seq_along(features), 1)
    old_par <- par(mar = c(3, 2, 3, 2))
    on.exit(par(old_par))
    plot(NA, xlim = c(-1.5, 1.5), ylim = c(-1.4, 1.4), asp = 1,
         axes = FALSE, xlab = "", ylab = "",
         main = "Applicant profile compared with cutoff applicant")
    for (level in c(0.25, 0.5, 0.75, 1)) {
      polygon(level * cos(angles[closed]), level * sin(angles[closed]),
              border = "#d6dde5")
      text(0.04, level, labels = paste0(level * 100), cex = 0.7,
           col = "#64748b", adj = 0)
    }
    segments(0, 0, cos(angles), sin(angles), col = "#d6dde5")
    text(1.2 * cos(angles), 1.2 * sin(angles),
         labels = c("GRE", "TOEFL", "University\nRating", "SOP", "LOR", "CGPA", "Research"),
         cex = 0.9)
    polygon(cutoff_values[closed] * cos(angles[closed]),
            cutoff_values[closed] * sin(angles[closed]),
            col = adjustcolor("#e69f00", alpha.f = 0.15),
            border = "#e69f00", lwd = 2, lty = 2)
    polygon(student_values[closed] * cos(angles[closed]),
            student_values[closed] * sin(angles[closed]),
            col = adjustcolor("#2878b5", alpha.f = 0.15),
            border = "#2878b5", lwd = 2)
    points(student_values * cos(angles), student_values * sin(angles),
           pch = 16, col = "#2878b5")
    legend("bottom", inset = 0, bty = "n", horiz = TRUE,
           legend = c(paste0("Applicant (rank ", profile$student$Rank, ")"),
                      paste0("Cutoff applicant (rank ", profile$cutoff$Rank, ")")),
           col = c("#2878b5", "#e69f00"), lty = c(1, 2), lwd = 2, cex = 0.85)
  })

  student_data <- eventReactive(input$predict, {

    data.frame(
      GRE_Score = input$gre,
      TOEFL_Score = input$toefl,
      University_Rating = input$university,
      SOP = input$sop,
      LOR = input$lor,
      CGPA = input$cgpa,
      Research = as.numeric(input$research)
    )
  })

  nb_result <- eventReactive(input$predict, {
    validate(need(is.null(nb_error) && !is.null(admission_data), "Naive Bayes model unavailable. Check the model file and dataset."))

    new_student <- student_data()

    predict_naive_bayes(new_student)
  })

  output$nb_classification <- renderText({

    req(nb_result())

    if (nb_result()$class == "1") {
      "High Admission Potential"
    } else {
      "Lower Admission Potential"
    }
  })

  output$nb_probability <- renderText({

    req(nb_result())

    paste0(
      "Probability of high admission: ",
      round(nb_result()$probability * 100, 2),
      "%"
    )
  })

  output$nb_metrics <- renderTable({
    validate(need(is.null(nb_error) && !is.null(admission_data), "Naive Bayes metrics unavailable."))
    nb_metrics_data
  })

  output$nb_confusion <- renderTable({
    validate(need(is.null(nb_error) && !is.null(admission_data), "Naive Bayes evaluation unavailable."))
    nb_confusion_data
  })

  prediction_result <- eventReactive(input$predict, {
    validate(need(!is.null(pca_regression_model), "Prediction model unavailable. Check the project dataset and restart."))

    new_student <- student_data()

    student_components <- predict(
      pca_model,
      newdata = new_student[, continuous_features]
    )

    model_input <- data.frame(
      PC1 = student_components[, "PC1"],
      PC2 = student_components[, "PC2"],
      Research = new_student$Research
    )

    prediction <- predict(
      pca_regression_model,
      newdata = model_input
    )

    # Keep prediction between 0 and 1
    prediction <- max(0, min(1, prediction))

    prediction
  })

  output$probability <- renderText({

    req(prediction_result())

    paste0(
      round(prediction_result() * 100, 2),
      "%"
    )
  })

  output$classification <- renderText({

    req(prediction_result())

    if (prediction_result() >= 0.75) {
      "High Admission Potential"
    } else {
      "Lower Admission Potential"
    }
  })

  output$interpretation <- renderText({

    req(prediction_result())

    if (prediction_result() >= 0.75) {
      paste(
        "Based on the PCA regression model, this student has",
        "a relatively high predicted chance of admission."
      )
    } else {
      paste(
        "Based on the PCA regression model, this student's",
        "predicted chance of admission is below the 75% threshold."
      )
    }
  })

  output$student_table <- renderTable({

    req(student_data())

    displayed_data <- student_data()

    names(displayed_data) <- c(
      "GRE Score",
      "TOEFL Score",
      "University Rating",
      "SOP",
      "LOR",
      "CGPA",
      "Research"
    )

    displayed_data$Research <- ifelse(
      displayed_data$Research == 1,
      "Yes",
      "No"
    )

    displayed_data
  })

  output$probability_plot <- renderPlot({

    req(prediction_result())

    probability <- prediction_result() * 100

    barplot(
      probability,
      ylim = c(0, 100),
      col = ifelse(probability >= 75, "#2ca58d", "#f4a261"),
      main = "Predicted Admission Probability",
      ylab = "Probability (%)",
      names.arg = "Student",
      border = NA,
      width = 0.4
    )

    abline(
      h = 75,
      col = "red",
      lty = 2,
      lwd = 2
    )

    text(
      x = 0.7,
      y = probability + 4,
      labels = paste0(round(probability, 2), "%"),
      font = 2
    )

    legend(
      "topright",
      legend = "75% classification threshold",
      col = "red",
      lty = 2,
      bty = "n"
    )
  })

  output$profile_plot <- renderPlot({

    req(student_data())

    student <- student_data()

    normalized_values <- c(
      student$GRE_Score / 340,
      student$TOEFL_Score / 120,
      student$University_Rating / 5,
      student$SOP / 5,
      student$LOR / 5,
      student$CGPA / 10,
      student$Research
    ) * 100

    barplot(
      normalized_values,
      names.arg = c(
        "GRE",
        "TOEFL",
        "University",
        "SOP",
        "LOR",
        "CGPA",
        "Research"
      ),
      ylim = c(0, 100),
      col = "#2878b5",
      main = "Student Scores as Percentages of Maximum",
      ylab = "Score / maximum (%)",
      las = 2,
      border = NA
    )
  })

  output$research_admission_plot <- renderPlot({
  req(!is.null(admission_data), nrow(admission_data) > 0)

  research_summary <- aggregate(
    admission_data$Admission_Class == "High Admission",
    by = list(Research = admission_data$Research),
    FUN = mean
  )

  names(research_summary)[2] <- "High_Admission_Rate"

  research_summary$Research_Label <- ifelse(
    research_summary$Research == 1,
    "Research Experience",
    "No Research Experience"
  )

  admission_percentages <- research_summary$High_Admission_Rate * 100

  bar_positions <- barplot(
    admission_percentages,
    names.arg = research_summary$Research_Label,
    ylim = c(0, 100),
    col = c("#f4a261", "#2ca58d"),
    main = "Research Experience vs High Admission Rate",
    ylab = "High Admission Rate (%)",
    border = NA
  )

  text(
    x = bar_positions,
    y = admission_percentages + 4,
    labels = paste0(
      round(admission_percentages, 1),
      "%"
    ),
    font = 2
  )

  abline(
    h = 50,
    col = "gray60",
    lty = 2
  )
})

output$university_admission_plot <- renderPlot({
  req(!is.null(admission_data), nrow(admission_data) > 0)

  university_summary <- aggregate(
    admission_data$Admission_Class == "High Admission",
    by = list(
      University_Rating = admission_data$University_Rating
    ),
    FUN = mean
  )

  names(university_summary)[2] <- "High_Admission_Rate"

  admission_percentages <-
    university_summary$High_Admission_Rate * 100

  bar_positions <- barplot(
    admission_percentages,
    names.arg = university_summary$University_Rating,
    ylim = c(0, 100),
    col = "#2878b5",
    main = "University Rating vs High Admission Rate",
    xlab = "University Rating",
    ylab = "High Admission Rate (%)",
    border = NA
  )

  text(
    x = bar_positions,
    y = admission_percentages + 4,
    labels = paste0(
      round(admission_percentages, 1),
      "%"
    ),
    font = 2
  )

  abline(
    h = 50,
    col = "gray60",
    lty = 2
  )
})

output$gre_boxplot <- renderPlot({
  req(!is.null(admission_data), nrow(admission_data) > 0)

  boxplot(
    GRE_Score ~ Admission_Class,
    data = admission_data,
    col = c("#f4a261", "#2ca58d"),
    main = "GRE Score by Admission Class",
    xlab = "Admission Class",
    ylab = "GRE Score",
    border = "#34495e"
  )

  stripchart(
    GRE_Score ~ Admission_Class,
    data = admission_data,
    vertical = TRUE,
    method = "jitter",
    add = TRUE,
    pch = 16,
    col = rgb(0, 0, 0, 0.20)
  )
})

output$toefl_boxplot <- renderPlot({
  req(!is.null(admission_data), nrow(admission_data) > 0)

  boxplot(
    TOEFL_Score ~ Admission_Class,
    data = admission_data,
    col = c("#f4a261", "#2ca58d"),
    main = "TOEFL Score by Admission Class",
    xlab = "Admission Class",
    ylab = "TOEFL Score",
    border = "#34495e"
  )

  stripchart(
    TOEFL_Score ~ Admission_Class,
    data = admission_data,
    vertical = TRUE,
    method = "jitter",
    add = TRUE,
    pch = 16,
    col = rgb(0, 0, 0, 0.20)
  )
})

output$cgpa_boxplot <- renderPlot({
  req(!is.null(admission_data), nrow(admission_data) > 0)

  boxplot(
    CGPA ~ Admission_Class,
    data = admission_data,
    col = c("#f4a261", "#2ca58d"),
    main = "CGPA by Admission Class",
    xlab = "Admission Class",
    ylab = "CGPA",
    border = "#34495e"
  )

  stripchart(
    CGPA ~ Admission_Class,
    data = admission_data,
    vertical = TRUE,
    method = "jitter",
    add = TRUE,
    pch = 16,
    col = rgb(0, 0, 0, 0.20)
  )
})

output$sop_lor_plot <- renderPlot({
  req(!is.null(admission_data), nrow(admission_data) > 0)

  sop_lor_summary <- aggregate(
    cbind(SOP, LOR) ~ Admission_Class,
    data = admission_data,
    FUN = mean
  )

  comparison_values <- rbind(
    sop_lor_summary$SOP,
    sop_lor_summary$LOR
  )

  colnames(comparison_values) <-
    sop_lor_summary$Admission_Class

  rownames(comparison_values) <- c(
    "SOP",
    "LOR"
  )

  bar_positions <- barplot(
    comparison_values,
    beside = TRUE,
    ylim = c(0, 5),
    col = c("#2878b5", "#e76f51"),
    main = "Average SOP and LOR by Admission Class",
    xlab = "Admission Class",
    ylab = "Average Rating",
    border = NA,
    legend.text = c(
      "Statement of Purpose",
      "Letter of Recommendation"
    ),
    args.legend = list(
      x = "topleft",
      bty = "n",
      cex = 0.8
    )
  )

  text(
    x = bar_positions,
    y = comparison_values + 0.15,
    labels = round(comparison_values, 2),
    font = 2,
    cex = 0.8
  )
})
}

shinyApp(ui = ui, server = server)
