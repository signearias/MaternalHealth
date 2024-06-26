# Load necessary libraries
library(tidyverse)
library(knitr)
library(readr)

#Install latex
if (!require(tinytex)) install.packages("tinytex")
library(tinytex)

# Import CSV file
url <- "https://raw.githubusercontent.com/signearias/MaternalHealth/5c76580bcac266c6145c6a7fb30ca301e0a80203/dataset.csv"
data <- read_csv(url)

# Data preview

## Check the first 10 rows
head(data, 10)

## Check for missing values in each column
sapply(data, function(x) sum(is.na(x)))


## Check for unique values in each column
sapply(data, function(x) length(unique(x)))

## Check summary statistics for each column
summary(data)

# Basic visualisation

## Histogram for Age distribution
ggplot(data, aes(x = Age)) +
  geom_histogram(binwidth = 1, fill = "darkgreen", color = "black") +
  labs(title = "Age Distribution", x = "Age", y = "Frequency")

## Boxplot for Heart Rate
ggplot(data, aes(y = HeartRate, x = RiskLevel)) +
  geom_boxplot() +
  labs(title = "Heart Rate by Risk Level", x = "Risk Level", y = "Heart Rate")

## Bar plot for Risk Level counts
ggplot(data, aes(x = RiskLevel, fill = RiskLevel)) +
  geom_bar() +
  labs(title = "Count of Risk Levels", x = "Risk Level", y = "Count")

# Clean data set

## Exclude rows where Age is below 16 and above 49
clean_data <- subset(data, Age >= 16 & Age <= 49)

## Further exclude rows where Heart Rate is below 50
clean_data <- subset(clean_data, HeartRate >= 50)

## Convert Risk Level to numeric values
clean_data$RiskLevelNumeric <- as.numeric(factor(clean_data$RiskLevel, levels = c("low risk", "mid risk", "high risk"), labels = c(1, 2, 3)))

## Display the cleaned data
summary(clean_data)

#Analyse correlation between each column and Risk Level (Numeric)

## Select numeric columns for correlation analysis
numeric_data <- clean_data[, sapply(clean_data, is.numeric)]

## Calculate correlation matrix
correlation_matrix <- cor(numeric_data)

## Extract correlation with RiskLevelNumeric
correlation_with_risk <- correlation_matrix[, "RiskLevelNumeric"]

## Display the correlation with RiskLevelNumeric

correlation_df <- tibble(Feature = names(correlation_with_risk), Correlation = correlation_with_risk)
correlation_df %>% knitr::kable()

# Create training and validation sets where 85% of rows are used for training

## Set a random seed for reproducibility
set.seed(12345)

## Determine the number of rows in the dataset
num_rows <- nrow(clean_data)
num_rows

## Create a random sample of row indices for the training set (85% of the data)
train_indices <- sample(seq_len(num_rows), size = 0.85 * num_rows)

## Create the training and validation datasets
training_data <- clean_data[train_indices, ]
validation_data <- clean_data[-train_indices, ]

## Display the number of rows in each dataset / Sense check
cat("Number of rows in clean data:", nrow(clean_data), "\n")
cat("Number of rows in training data:", nrow(training_data), "\n")
cat("Number of rows in validation data:", nrow(validation_data), "\n")

##Install and load patchwork that allows us to display two plots side by side
if (!require(patchwork)) install.packages("patchwork")
library(patchwork)

## Plot both validation and training data sets
plot_training <- ggplot(training_data, aes(x = RiskLevelNumeric, fill = RiskLevel)) +
  geom_bar() +
  labs(title = "Training Data", x = "Risk Level", y = "Count")

plot_validation <- ggplot(validation_data, aes(x = RiskLevelNumeric, fill = RiskLevel)) +
  geom_bar() +
  labs(title = "Validation Data", x = "Risk Level", y = "Count")

## Combine plots side by side using patchwork
combined_plot <- plot_training + plot_validation
combined_plot

# Train various models and test accuracy to choose best model

## Install necessary packages
if (!require(rpart)) install.packages("rpart")
if (!require(e1071)) install.packages("e1071")
if (!require(randomForest)) install.packages("randomForest")

## Load libraries to train models
library(rpart)
library(e1071)
library(randomForest)

## Train a decision tree classifier
decision_tree_model <- rpart(RiskLevelNumeric ~ ., data = training_data, method = "class")

## Train a linear SVM classifier
svm_model <- svm(RiskLevelNumeric ~ ., data = training_data, kernel = "linear")

## Train a linear regression model
linear_regression_model <- lm(RiskLevelNumeric ~ ., data = training_data)

## Train a random forest model
random_forest_model <- randomForest(RiskLevelNumeric ~ ., data = training_data)

## Make predictions using the validation data
dt_predictions <- predict(decision_tree_model, validation_data, type = "class")
svm_predictions <- predict(svm_model, validation_data)
linear_regression_predictions <- round(predict(linear_regression_model, validation_data))
random_forest_predictions <- predict(random_forest_model, validation_data)

## Calculate accuracy for decision tree
dt_accuracy <- sum(dt_predictions == validation_data$RiskLevelNumeric) / nrow(validation_data)
cat("Decision Tree Accuracy:", dt_accuracy, "\n")

## Calculate accuracy for SVM
svm_accuracy <- sum(svm_predictions == validation_data$RiskLevelNumeric) / nrow(validation_data)
cat("SVM Accuracy:", svm_accuracy, "\n")

## Calculate accuracy for linear regression
linear_regression_accuracy <- sum(linear_regression_predictions == validation_data$RiskLevelNumeric) / nrow(validation_data)
cat("Linear Regression Accuracy:", linear_regression_accuracy, "\n")

## Calculate accuracy for random forest
random_forest_accuracy <- sum(random_forest_predictions == validation_data$RiskLevelNumeric) / nrow(validation_data)
cat("Random Forest Accuracy:", random_forest_accuracy, "\n")

## Compare the accuracy scores and display in a table
accuracies <- c(dt_accuracy, svm_accuracy, linear_regression_accuracy, random_forest_accuracy)
names(accuracies) <- c("Decision Tree", "SVM", "Linear Regression", "Random Forest")

accuracies_df <- tibble(Model = names(accuracies), Accuracy = accuracies)
accuracies_df %>% knitr::kable()

# Remove parameters and test accuracy of models with less data

## Create subset of training and validation datasets that excludes body temperature (lowest correlation)

training_data_subset <- training_data[, setdiff(names(training_data), "BodyTemp")]

validation_data_subset <- validation_data[, setdiff(names(validation_data), "BodyTemp")]

## Train a decision tree classifier using the subset
decision_tree_model_2 <- rpart(RiskLevelNumeric ~ ., data = training_data_subset, method = "class")

## Evaluate new model
dt_predictions_2 <- predict(decision_tree_model_2, validation_data_subset, type = "class")

## Calculate accuracy for decision tree model 2
dt_accuracy_2 <- sum(dt_predictions_2 == validation_data_subset$RiskLevelNumeric) / nrow(validation_data_subset)
cat("Decision Tree Accuracy #2:", dt_accuracy_2, "\n")
cat("Compared to full model Accuracy:", dt_accuracy, "\n")
