library(shiny)
library(tidyverse)
library(plotly)

ui <- fluidPage(
    titlePanel("Sample Size Estimation in Diagnostic Accuracy Studies"),

    sidebarLayout(
        sidebarPanel(
            numericInput("sensitivity", "Expected Sensitivity (%)", value = 80, min = 0, max = 100),
            conditionalPanel(
                condition = "input.sensitivity < 0 || input.sensitivity > 100",
                div(style = "color: red;", "Error: Sensitivity must be between 0 and 100")
            ),
            numericInput("specificity", "Expected Specificity (%)", value = 98, min = 0, max = 100),
            conditionalPanel(
                condition = "input.specificity < 0 || input.specificity > 100",
                div(style = "color: red;", "Error: Specificity must be between 0 and 100")
            ),
            numericInput("confidence", "Confidence Level (%)", value = 95, min = 90, max = 99),
            numericInput("margin", "Margin of Error (%)", value = 5, min = 1, max = 10),
            actionButton("calculate", "Calculate")
        ),

        mainPanel(
            h3("Sample Size Calculation Results"),
            verbatimTextOutput("results"),
            plotlyOutput("resultsPlot", height = "400px", width = "50%")
        )
    )
)

server <- function(input, output) {
    calculate_sample_size <- reactive({
        req(input$sensitivity, input$specificity, input$confidence, input$margin)
        
        sens <- input$sensitivity / 100
        spec <- input$specificity / 100
        conf <- input$confidence / 100
        margin <- input$margin / 100
        
        # Sample size formulas for sensitivity and specificity
        z <- qnorm(1 - (1 - conf) / 2)
        n_sens <- ((z^2 * sens * (1 - sens)) / (margin^2)) %>% ceiling()
        n_spec <- ((z^2 * spec * (1 - spec)) / (margin^2)) %>% ceiling()

        return(list(n_sens = n_sens, n_spec = n_spec))
    })

    output$resultsPlot <- renderPlotly({
        input$calculate
        isolate({
            sample_size <- calculate_sample_size()
            bar_data <- data.frame(
                Metric = c("Sensitivity", "Specificity"),
                SampleSize = c(sample_size$n_sens, sample_size$n_spec)
            )
            
            p <- ggplot(bar_data, aes(x = Metric, y = SampleSize, fill = Metric)) +
                geom_bar(stat = "identity", position = "dodge") +
                theme_minimal() +
                ggtitle("Sample Size Estimation") +
                geom_text(aes(label = SampleSize), vjust = -0.25) +
                ylab("Sample Size") +
                xlab("Metric") + 
                theme_bw()
            
            ggplotly(p, tooltip = "SampleSize")
        })
    })

    output$results <- renderText({
        input$calculate
        isolate({
            sample_size <- calculate_sample_size()
            paste(
            " Sample size based on sensitivity estimation: ", sample_size$n_sens, "\n","Sample size based on specificity estimation: ", sample_size$n_spec
            )
        })
    })

}

# Run the application 
shinyApp(ui = ui, server = server)
