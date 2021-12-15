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
                                              borough = as.factor(c(input$borough, 'Manhattan', 'Brooklyn'))
                                          ))
        # Select only the first column the correspond to input$borough
        ordinal_pred <- ordinal_pred %>% 
            as.matrix() %>% 
            as_tibble() %>% 
            select(1)
        
        df <- as.data.frame(ordinal_pred) %>%
            mutate(Classification  = case_when(
                `1` == 1 ~ 'Poor',
                `1` == 2 ~ 'Typical',
                `1` == 3 ~ 'Excellent' )) %>%
            dplyr::select(Classification)
        
        tab <- table(df) %>% sort(decreasing=TRUE) %>% prop.table()
        names(dimnames(tab)) <- c("Transit Accessibility")
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
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
    ), 
    titlePanel("New York City Subway Desert Prediction With Ordinal Model"),
    p("Project By: Freddy Barragan, Juthi Dewan, Sam Ding, Vichearith Meas", id = 'author'),
    p('13th December, 2021', id= 'date'),
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
            h2("About"),
            br(),
            p("This shinny app is an extension of Neighborhood Deserts: Transportation Access & Housing Disparities in NYC Capstone Project",
              a("(Link)", href = "https://freddybarragan.netlify.app/project/bayes_cap/"), "for",
              a("STAT 454: Bayesian Statistics", href = "https://catalog.macalester.edu/preview_course_nopop.php?catoid=23&coid=121763"), " of Macalester College"),
            br(),
            p('The Shinny App serve as an interactive tool for readers to interact with our pre-trained', strong('ordinal model'), 'from our capstone project.'),
            p('This odinal model takes values of four predictors to make prediction about the category of subway coverage in a neighbor in New York City'),
            br(),
            h2('Instruction'),
            br(),
            p('Please use the user interface in the left panel to change the predictors. The prediction from the ordinal model will be display in the table below.'),
         
            h2("Ordinal Model Predictions"), 
            tableOutput("resultTableOrdinal"),
            tableOutput("resultTableNaive")
        )
    )
)

# Run the shiny app!
shinyApp(ui = ui2, server = server2)

