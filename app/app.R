library(shiny)

# ---------------------------------------------------------
# Load and prepare dataset
# ---------------------------------------------------------

data_path <- file.path("..", "data", "Graduate_Admissions.csv")

admission_data <- read.csv(data_path)
source("naive_bayes_model.R", local = TRUE)


continuous_features <- c(
  "GRE_Score",
  "TOEFL_Score",
  "University_Rating",
  "SOP",
  "LOR",
  "CGPA"
)

# ---------------------------------------------------------
# Train PCA and PCA regression model
# ---------------------------------------------------------

pca_model <- prcomp(
  admission_data[, continuous_features],
  center = TRUE,
  scale. = TRUE
)

pca_scores <- as.data.frame(pca_model$x[, 1:2])

pca_training_data <- data.frame(
  Chance_of_Admit = admission_data$Chance_of_Admit,
  PC1 = pca_scores$PC1,
  PC2 = pca_scores$PC2,
  Research = admission_data$Research
)

pca_regression_model <- lm(
  Chance_of_Admit ~ PC1 + PC2 + Research,
  data = pca_training_data
)

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
  ),

  div(
    class = "title-box",
    h1("University Admission Analysis"),
    p("PCA Regression Prediction Dashboard")
  ),

  sidebarLayout(

    sidebarPanel(

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
    ),

    mainPanel(

      tabsetPanel(

        tabPanel(
          "Prediction",

          div(
            class = "result-box",
            h2("Predicted Admission Chance"),
            h1(textOutput("probability")),
            h3(textOutput("classification")),
            p(textOutput("interpretation"))
          ),

          plotOutput("probability_plot", height = "300px")
        ),

        tabPanel(
          "Student Profile",
          h3("Entered Student Information"),
          tableOutput("student_table"),
          plotOutput("profile_plot", height = "400px")
        ),

        tabPanel(
          "Naive Bayes",

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
  )
)

# ---------------------------------------------------------
# Server logic
# ---------------------------------------------------------

server <- function(input, output, session) {

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
    nb_metrics_data
  })

  output$nb_confusion <- renderTable({
    nb_confusion_data
  })

  prediction_result <- eventReactive(input$predict, {

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
      main = "Normalized Student Profile",
      ylab = "Relative Score (%)",
      las = 2,
      border = NA
    )
  })
}

shinyApp(ui = ui, server = server)
