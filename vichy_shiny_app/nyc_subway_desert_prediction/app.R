#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#




library(shiny)
library(bayesrules)  # for the plotting functions
library(rstanarm)
library(dplyr)


ordinal_model <- readRDS("shiny_app_ordinal_model.rds")
# naive_model<- readRDS("shiny_app_naive_model.rds")

# Build the server
server2 <- function(input, output) {
    
    output$resultTableOrdinal <- renderTable({
        # Prediciton from model
        ordinal_pred <- posterior_predict(ordinal_model,
                                          newdata = data.frame(
                                              mean_income  = input$mean_income,
                                              below_poverty_perc  = input$below_poverty_perc,
                                              store_count = input$store_count,
                                              borough = input$borough
                                          ))
        
        df <- as.data.frame(ordinal_pred) %>%
            mutate(Classification  = case_when(
                `1` == 1 ~ 'Poor',
                `1` == 2 ~ 'Typical',
                `1` == 3 ~ 'Excellent' )) %>%
            dplyr::select(Classification)
        
        tab <- table(df) %>% sort(decreasing=TRUE) %>% prop.table()
        names(dimnames(tab)) <- c("Transit_Accessibility")
        tab
    })
    
    # 
    #     output$resultTableNaive <- renderTable({
    #        # Prediciton from model
    #       naive_pre <- predict(naive_model,
    #           newdata = data.frame(
    #                             mean_income  = input$mean_income,
    #                              below_poverty_perc  = input$below_poverty_perc,
    #                              store_count = input$store_count
    #                           )
    #         , type = "raw")
    #       naive_pre
    
    # tab <- df %>% sort(decreasing=TRUE)
    # names(dimnames(tab)) <- c("Transit_Accessibility")
    # tab)}

}


# Build the user interface
ui2 <- fluidPage(
    sidebarLayout(
        sidebarPanel(
            sliderInput("mean_income", "Mean Income per Year (in USD)", min = 0, max = 300000, value = 10),
            sliderInput("below_poverty_perc", "% Below Poverty", min = 0, max = 100, value = 1),
            sliderInput("store_count", "Store Count", min = 0, max = 250, value = 1), 
            selectInput("borough", "Select NYC Borough:",
                        as.factor(c("Brooklyn" ,
                          "Queens"  ,
                          "Manhattan",
                          "Bronx")))
        ),
        mainPanel(
            h4("Model Predictions"), 
            tableOutput("resultTableOrdinal"),
            tableOutput("resultTableNaive")
        )
    )
)

# Run the shiny app!
shinyApp(ui = ui2, server = server2)

