if (!requireNamespace("e1071", quietly = TRUE)) {
  stop("Package 'e1071' is required. Install it with install.packages('e1071').")
}

nb_features <- c(
  "GRE_Score", "TOEFL_Score", "University_Rating",
  "SOP", "LOR", "CGPA", "Research"
)

nb_training_data <- admission_data
nb_training_data$Admit_Binary <- factor(
  ifelse(nb_training_data$Chance_of_Admit >= 0.75, 1, 0),
  levels = c(0, 1)
)

nb_model <- e1071::naiveBayes(
  Admit_Binary ~ GRE_Score + TOEFL_Score + University_Rating +
    SOP + LOR + CGPA + Research,
  data = nb_training_data
)

predict_naive_bayes <- function(new_student) {
  model_data <- new_student[, nb_features, drop = FALSE]
  probabilities <- predict(nb_model, newdata = model_data, type = "raw")
  predicted_class <- predict(nb_model, newdata = model_data, type = "class")

  list(
    class = as.character(predicted_class[1]),
    probability = as.numeric(probabilities[1, "1"]),
    all_probabilities = probabilities[1, ]
  )
}

# Results already obtained from the notebook's held-out test set.
nb_metrics_data <- data.frame(
  Metric = c("Accuracy", "Precision", "Recall", "Specificity", "F1-score"),
  Value = c(0.8625, 0.7812, 0.8621, 0.8627, 0.8197)
)

nb_confusion_data <- data.frame(
  Actual = c("0", "1"),
  Predicted_0 = c(44, 4),
  Predicted_1 = c(7, 25),
  check.names = FALSE
)


