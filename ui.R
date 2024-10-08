#libraries----

#packages <- c("librarian")

#installed_packages <- packages %in% rownames(installed.packages())
#if (any(installed_packages == FALSE)) {
#  install.packages(packages[!installed_packages])
#}

#librarian::shelf(
#  shiny, shinydashboard, shinydashboardPlus, shinyWidgets, DT, plotly,
#  update_all = FALSE
#)

library('shiny')
library('shinydashboard')
library('shinydashboardPlus')
library('shinyWidgets')
library('DT')
library('plotly')


# ui----

ui <- shinydashboardPlus::dashboardPage(
  skin = "midnight",
  title = "EricLarG4: G4 CD/IDS PCA",
  options = list(sidebarExpandOnHover = TRUE),
  scrollToTop = TRUE,
  header = dashboardHeader(
    title = "G4 CD/IDS PCA",
    fixed = FALSE,
    leftUi = tagList(
      dropdownBlock(
        id = 'fig.export',
        title = 'Figure export',
        checkboxInput("apply.thematic", "Apply dark theme on figures", value = TRUE),
        selectInput("device", "Device:", choices = c("png", "pdf"), selected = "png"),
        numericInput("width", "Width (cm)", value = 15),
        numericInput("height", "Height (cm)", value = 15),
        numericInput("scaling", "Scaling", value = 1),
        numericInput("resolution", "Resolution (dpi)", value = 600)
      )
    ),
    controlbarIcon = icon('filter')
  ),
  #right sidebar----
  controlbar = dashboardControlbar(
    id = 'control',
    skin = 'dark',
    width = 300,
    collapsed = TRUE,        
    controlbarMenu(
      id = 'datafilter',        
      controlbarItem(
        title = 'Data filters',
        icon = icon('filter'),
        uiOutput("ref.seq.topo.0"),
        uiOutput("ref.seq.gba.0"),
        uiOutput("ref.seq.tetrad.0"),
        uiOutput("ref.seq.tetrad.id.0"),
        uiOutput("ref.seq.loop.0"),
        uiOutput("ref.seq.plus.minus.0"),
        uiOutput("ref.seq.groove.0"),
        uiOutput("ref.seq.cation.0"),
        uiOutput("ref.seq.oligo.0"),
        uiOutput("user.seq.oligo.0")
      )
    )
  ),
  #sidebar----
  sidebar = shinydashboardPlus::dashboardSidebar(
    minified = TRUE, 
    collapsed = FALSE,
    sidebarMenu(
      id = "sidebarmenu",
      ##ref data input----
      menuItem(     
        id = "tabinput",
        text = "Data input",
        icon = icon("file-excel"),
        startExpanded = TRUE,
        menuSubItem(
          text = "View data",
          tabName = "tabinput",
          selected = TRUE
        ),    
        fileInput(
          "ref.data", 
          "Select reference data file",
          multiple = FALSE,
          accept = c(".xlsx", ".xls")
        ),
        verbatimTextOutput("file_toggle_value"),
        fileInput(
          "user.data", 
          "Select user data file",
          multiple = FALSE,
          accept = c(".xlsx", ".xls")
        )
        ##data filtering----
        # uiOutput("ref.seq.topo.0"),
        # uiOutput("ref.seq.gba.0"),
        # uiOutput("ref.seq.tetrad.0"),
        # uiOutput("ref.seq.tetrad.id.0"),
        # uiOutput("ref.seq.loop.0"),
        # uiOutput("ref.seq.plus.minus.0"),
        # uiOutput("ref.seq.groove.0"),
        # uiOutput("ref.seq.cation.0"),
        # uiOutput("ref.seq.oligo.0"),
        # uiOutput("user.seq.oligo.0")
      ),
      menuItem(
        id = 'tabplot',
        text = 'Data plots',
        icon = icon("compass-drafting"),
        startExpanded = TRUE,
        selected = FALSE,
        menuSubItem(
          text = "View plots",
          tabName = "tabplot",
          selected = TRUE
        ),  
        prettyToggle(
          inputId = "ids.ref.select",
          label_on = "Theoretical UV reference",
          label_off = "User UV reference",
          value = TRUE,
          shape = "round",
          width = "100%",
          bigger = TRUE,
          animation = "pulse"
        ),
        sliderInput(
          inputId = "wl",
          label = "Wavelength (nm)",
          min = 220,
          max = 350,
          value = c(220, 310),
          step = 5
        ),
        selectInput(
          inputId = "ids.norm",
          label = "IDS normalization",
          choices = c("Δε", "-1/+1"),
          selected = "Δε"
        ),
        selectInput(
          inputId = "cd.norm",
          label = "CD normalization",
          choices = c("Δε", "Δε/ε", "-1/+1"),
          selected = "Δε"
        )
      ),
      menuItem(
        id = "tabpca",
        text = "PCA",
        icon = icon("object-ungroup"),
        startExpanded = TRUE,
        menuSubItem(
          text = "View PCA",
          tabName = "tabpca",
          selected = FALSE
        ),
        ##processing parameters----
        sliderInput(
          inputId = "ncp",
          label = "PCA dimensions",
          min = 2,
          max = 10,
          value = 3,
          step = 1
        ),
        prettyToggle(
          inputId = "scale.unit",
          label_on = "Scaled to unit variance",
          label_off = "Not scaled to variance",
          value = FALSE,
          shape = "round",
          width = "100%",
          bigger = TRUE,
          animation = "pulse"
        ),
        selectInput(
          inputId = "k.mean.algo",
          label = "k-means algorithm",
          choices = c("Hartigan-Wong", "Lloyd", "Forgy", "MacQueen"),
          selected = "Hartigan-Wong"
        ),
        sliderInput(
          inputId = "cluster.center",
          label = "k-means centers",
          min = 2,
          max = 10,
          value = 4,
          step = 1
        ),
        actionBttn(
          inputId = "button.cd.invest",
          label = "Investigate CD",
          style = "simple",
          size = "sm",
          color = "royal"
        ),
        actionBttn(
          inputId = "button.ids.invest",
          label = "Investigate IDS",
          style = "simple",
          size = "sm",
          color = "royal"
        ),
        actionBttn(
          inputId = "button.cd.ids.invest",
          label = "Investigate CD+IDS",
          style = "simple",
          size = "sm",
          color = "royal"
        )
      )
    )
  ),
  #body----
  body = dashboardBody(
    includeCSS("www/uireboot.css"),
    # error message management
    tags$head(tags$style(".shiny-output-error{visibility: hidden}")),
    tags$head(tags$style(".shiny-output-error:after{content: 'Please wait. If this message does not disappear, an error has occurred.';visibility: visible}")),
    tabItems(
      ##Input----
      tabItem(
        tabName = "tabinput",
        shinydashboardPlus::box(
          id = 'databox',
          title = "Data",
          width = 12,
          # height = 48,
          collapsible = TRUE,
          collapsed = FALSE,
          tabsetPanel(
            ###ref panel----
            tabPanel(
              title = "Reference data",
              tabsetPanel(
                tabPanel(
                  title = "Oligonucleotide information",
                  DTOutput(
                    "seq",
                    height = "1200px"
                  )
                ),        
                tabPanel(
                  title = "UV/vis data",
                  DTOutput("ref.uv")
                ),   
                tabPanel(
                  title = "IDS data",
                  DTOutput("ref.ids")
                ),
                tabPanel(
                  title = "CD data",
                  DTOutput("ref.cd")
                ),
                tabPanel(
                  title = "training IDS",
                  DTOutput("training.ids")
                ),
                tabPanel(
                  title = "training CD",
                  DTOutput("training.cd")
                )
              )
            ),
            ###user panel----
            tabPanel(
              title = "User data",
              tabsetPanel(
                tabPanel(
                  title = "UV data",
                  DTOutput("user.uv.input")
                ),
                tabPanel(
                  title = "IDS data",
                  DTOutput("user.ids.input")
                ),
                tabPanel(
                  title = "CD data",
                  DTOutput("user.cd.input")
                ),
                tabPanel(
                  title = "IDS set for PCA",
                  DTOutput("user.ids")
                ),
                tabPanel(
                  title = "CD set for PCA",
                  DTOutput("user.cd")
                ),
                tabPanel(
                  title = "CD+IDS set for PCA",
                  DTOutput("user.cd.ids")
                )
              )
            )
          )
        )
      ),
      ##Plots----
      tabItem(
        tabName = "tabplot", 
        title = "Plot tab",
        ###ref----
        shinydashboardPlus::box(
          title = "Plots",
          collapsible = TRUE,
          width = 12,
          sidebar = boxSidebar(
            id = "ref.sidebar",
            icon = shiny::icon("cogs"),
            startOpen = FALSE,
            width = 25,
            box(
              title = "Data filters",
              width = 12,
              collapsible = TRUE,
              collapsed = FALSE,
              uiOutput("ref.seq.topo"),
              uiOutput("ref.seq.gba"),
              uiOutput("ref.seq.tetrad"),
              uiOutput("ref.seq.tetrad.id"),
              uiOutput("ref.seq.loop"),
              uiOutput("ref.seq.plus.minus"),
              uiOutput("ref.seq.groove"),
              uiOutput("ref.seq.cation"),
              uiOutput("ref.seq.oligo")
            ),
            box(
              title = "Plot options",
              width = 12,
              collapsible = TRUE,
              collapsed = FALSE,
              pickerInput(
                inputId = "ref.panel",
                label = "Layout",
                choices = c("Panels", "Superimposed", "Mean"),
                selected = "Panels"
              ),
              pickerInput(
                inputId = "ref.color",
                label = "Coloring",
                choices = c("Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression",
                            "Tetrad handedness", "Grooves", "Cation"),
                selected = "Topology"
              )
            ),
            box(
              title = 'User data',
              width = 12,
              collapsible = TRUE,
              collapsed = FALSE,
              uiOutput("user.seq.oligo"),
              pickerInput(
                inputId = "user.panel",
                label = "Layout",
                choices = c("Panels", "Superimposed"),
                selected = "Panels"
              )
            )
          ),
          tabsetPanel(
            tabPanel(
              title = 'Reference data',
              tabsetPanel(
                tabPanel(
                  title = "UV/vis plots",     
                  plotOutput(
                    "p.ref.uv",
                    height = "1200px"
                  )
                ),
                tabPanel(
                  title = "IDS plots",
                  plotOutput(
                    "p.ref.ids",
                    height = "1200px"
                  )
                ),        
                tabPanel(
                  title = "CD",
                  plotOutput(
                    "p.ref.cd",
                    height = "1200px"
                  )
                )
              )
            ),
            tabPanel(
              title = 'User data',
              tabsetPanel(
                tabPanel(
                  title = "UV/vis plots",     
                  plotOutput(
                    "p.user.uv",
                    height = "1200px"
                  )
                ),
                tabPanel(
                  title = "IDS plots",
                  plotOutput(
                    "p.user.ids",
                    height = "1200px"
                  )
                ), 
                tabPanel(
                  title = "CD",
                  plotOutput(
                    "p.user.cd",
                    height = "1200px"
                  )
                )
              )
            )
          )
        )
      ),
      ##PCA----
      tabItem(
        title = "PCA",
        tabName = 'tabpca',
        tabsetPanel(
          ###CD----
          tabPanel(
            title = "CD",
            shinydashboardPlus::box(
              title = "PCA viewer 1",
              collapsible = TRUE,
              width = 6,
              sidebar = boxSidebar(
                id = "pca.sidebar.cd",
                icon = shiny::icon("cogs"),
                startOpen = TRUE,
                width = 25,
                pickerInput(
                  inputId = "dim.cd",
                  label = "Dimensions",
                  choices = paste0("Dim.", 1:10),
                  multiple = TRUE,
                  selected = c("Dim.1", "Dim.2")
                ),            
                selectInput(
                  inputId = "pca.color.cd",
                  label = "PCA colors",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression", 'Tetrads x Loops',
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "Topology"
                ),
                selectInput(
                  inputId = "pca.shape.cd",
                  label = "PCA shapes",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression", 'Tetrads x Loops',
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "Topology"
                ),
                #download button
                downloadButton("dwn.pca.cd", "Download")
              ),
              tabsetPanel(
                tabPanel(
                  title = "Individual coordinates",
                  plotOutput(
                    "pca.cd.coord",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Predictions",
                  plotOutput(
                    "predict.cd.coord",
                    height = "800px"
                  )
                )
              )
            ),            
            shinydashboardPlus::box(
              title = "PCA viewer 2",
              collapsible = TRUE,
              width = 6,
              sidebar = boxSidebar(
                id = "pca.sidebar.cd.2",
                icon = shiny::icon("cogs"),
                startOpen = TRUE,
                width = 25,
                pickerInput(
                  inputId = "dim.cd.2",
                  label = "Dimensions",
                  choices = paste0("Dim.", 1:10),
                  multiple = TRUE,
                  selected = c("Dim.1", "Dim.2")
                ),            
                selectInput(
                  inputId = "pca.color.cd.2",
                  label = "PCA colors",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression", 'Tetrads x Loops',
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "GBA"
                ),
                selectInput(
                  inputId = "pca.shape.cd.2",
                  label = "PCA shapes",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression", 'Tetrads x Loops',
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "GBA"
                ),
                #download button
                downloadButton("dwn.pca.cd.2", "Download")
              ),
              tabsetPanel(
                tabPanel(
                  title = "Individual coordinates",
                  plotOutput(
                    "pca.cd.coord.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Predictions",
                  plotOutput(
                    "predict.cd.coord.2",
                    height = "800px"
                  )
                )
              )
            ),
            shinydashboardPlus::box(
              title = "PCA analytics 1",
              collapsible = TRUE,
              width = 6,
              tabsetPanel(
                tabPanel(
                  title = "Data table",
                  DTOutput("pca.cd.table")
                ),
                tabPanel(
                  title = "Parameters table",
                  DTOutput("param.cd.table")
                ),
                tabPanel(
                  title = "Predict data table",
                  DTOutput("predict.cd.table")
                ),
                tabPanel(
                  title = "Scree",
                  plotOutput(
                    "pca.cd.scree",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Factor map",
                  plotOutput(
                    "pca.cd.fac.map",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Correlation circle",
                  plotOutput(
                    "pca.cd.var.cor",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Variable contributions",
                  plotOutput(
                    "pca.cd.var.coord",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Total within sum of squares",
                  plotOutput(
                    "pca.cd.twss",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Gap statistic",
                  plotOutput(
                    "pca.cd.gap",
                    height = "800px"
                  )
                )
              )
            ),
            shinydashboardPlus::box(
              title = "PCA analytics 2",
              collapsible = TRUE,
              width = 6,
              tabsetPanel(
                tabPanel(
                  title = "Scree",
                  plotOutput(
                    "pca.cd.scree.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Factor map",
                  plotOutput(
                    "pca.cd.fac.map.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Correlation circle",
                  plotOutput(
                    "pca.cd.var.cor.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Variable contributions",
                  plotOutput(
                    "pca.cd.var.coord.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Total within sum of squares",
                  plotOutput(
                    "pca.cd.twss.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Gap statistic",
                  plotOutput(
                    "pca.cd.gap.2",
                    height = "800px"
                  )
                )
              )
            )
          ),
          ###IDS----
          tabPanel(
            title = "IDS",
            shinydashboardPlus::box(
              title = "PCA viewer 1",
              collapsible = TRUE,
              width = 6,
              sidebar = boxSidebar(
                id = "pca.sidebar.ids",
                icon = shiny::icon("cogs"),
                startOpen = TRUE,
                width = 25,
                pickerInput(
                  inputId = "dim.ids",
                  label = "Dimensions",
                  choices = paste0("Dim.", 1:10),
                  multiple = TRUE,
                  selected = c("Dim.1", "Dim.2")
                ),
                selectInput(
                  inputId = "pca.color.ids",
                  label = "PCA colors",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression", 'Tetrads x Loops',
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "Topology"
                ),
                selectInput(
                  inputId = "pca.shape.ids",
                  label = "PCA shapes",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression", 'Tetrads x Loops',
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "Topology"
                ),
                #download button
                downloadButton("dwn.pca.ids", "Download")
              ),
              tabsetPanel(
                tabPanel(
                  title = "Individual coordinates",
                  plotOutput(
                    "pca.ids.coord",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Predictions",
                  plotOutput(
                    "predict.ids.coord",
                    height = "800px"
                  )
                )
              )
            ),
            shinydashboardPlus::box(
              title = "PCA viewer 2",
              collapsible = TRUE,
              width = 6,
              sidebar = boxSidebar(
                id = "pca.sidebar.ids.2",
                icon = shiny::icon("cogs"),
                startOpen = TRUE,
                width = 25,
                pickerInput(
                  inputId = "dim.ids.2",
                  label = "Dimensions",
                  choices = paste0("Dim.", 1:10),
                  multiple = TRUE,
                  selected = c("Dim.1", "Dim.2")
                ),
                selectInput(
                  inputId = "pca.color.ids.2",
                  label = "PCA colors",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression", 'Tetrads x Loops',
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "GBA"
                ),
                selectInput(
                  inputId = "pca.shape.ids.2",
                  label = "PCA shapes",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression", 'Tetrads x Loops',
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "GBA"
                ),
                #download button
                downloadButton("dwn.pca.ids.2", "Download")
              ),
              tabsetPanel(
                tabPanel(
                  title = "Individual coordinates",
                  plotOutput(
                    "pca.ids.coord.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Predictions",
                  plotOutput(
                    "predict.ids.coord.2",
                    height = "800px"
                  )
                )
              )
            ),
            shinydashboardPlus::box(
              title = "PCA analytics 1",
              collapsible = TRUE,
              width = 6,
              tabsetPanel(
                tabPanel(
                  title = "Data table",
                  DTOutput("pca.ids.table")
                ),
                tabPanel(
                  title = "Parameters table",
                  DTOutput("param.ids.table")
                ),
                tabPanel(
                  title = "Scree",
                  plotOutput(
                    "pca.ids.scree",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Factor map",
                  plotOutput(
                    "pca.ids.fac.map",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Correlation circle",
                  plotOutput(
                    "pca.ids.var.cor",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Variable contributions",
                  plotOutput(
                    "pca.ids.var.coord",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Total within sum of squares",
                  plotOutput(
                    "pca.ids.twss",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Gap statistic",
                  plotOutput(
                    "pca.ids.gap",
                    height = "800px"
                  )
                )
              )
            ),
            shinydashboardPlus::box(
              title = "PCA analytics 2",
              collapsible = TRUE,
              width = 6,
              tabsetPanel(
                tabPanel(
                  title = "Scree",
                  plotOutput(
                    "pca.ids.scree.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Factor map",
                  plotOutput(
                    "pca.ids.fac.map.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Correlation circle",
                  plotOutput(
                    "pca.ids.var.cor.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Variable contributions",
                  plotOutput(
                    "pca.ids.var.coord.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Total within sum of squares",
                  plotOutput(
                    "pca.ids.twss.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Gap statistic",
                  plotOutput(
                    "pca.ids.gap.2",
                    height = "800px"
                  )
                )
              )
            )
          ),
          ###CD+IDS----
          tabPanel(
            title = "CD + IDS (Scaling advised!)",
            shinydashboardPlus::box(
              title = "PCA viewer 1",
              collapsible = TRUE,
              width = 6,
              sidebar = boxSidebar(
                id = "pca.sidebar.cd.ids",
                icon = shiny::icon("cogs"),
                startOpen = TRUE,
                width = 25,
                pickerInput(
                  inputId = "dim.cd.ids",
                  label = "Dimensions",
                  choices = paste0("Dim.", 1:10),
                  multiple = TRUE,
                  selected = c("Dim.1", "Dim.2")
                ),
                selectInput(
                  inputId = "pca.color.cd.ids",
                  label = "PCA colors",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression",
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "Topology"
                ),
                selectInput(
                  inputId = "pca.shape.cd.ids",
                  label = "PCA shapes",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression",
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "Topology"
                )
              ),
              tabsetPanel(
                tabPanel(
                  title = "Individual coordinates",
                  plotOutput(
                    "pca.cd.ids.coord",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Predictions",
                  plotOutput(
                    "predict.cd.ids.coord",
                    height = "800px"
                  )
                )
              )
            ),
            shinydashboardPlus::box(
              title = "PCA viewer 2",
              collapsible = TRUE,
              width = 6,
              sidebar = boxSidebar(
                id = "pca.sidebar.cd.ids.2",
                icon = shiny::icon("cogs"),
                startOpen = TRUE,
                width = 25,
                pickerInput(
                  inputId = "dim.cd.ids.2",
                  label = "Dimensions",
                  choices = paste0("Dim.", 1:10),
                  multiple = TRUE,
                  selected = c("Dim.1", "Dim.2")
                ),
                selectInput(
                  inputId = "pca.color.cd.ids.2",
                  label = "PCA colors",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression",
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "GBA"
                ),
                selectInput(
                  inputId = "pca.shape.cd.ids.2",
                  label = "PCA shapes",
                  choices = c("k-means", "Topology", "GBA", "Tetrads", "Tetrad combination", "Loop progression",
                              "Tetrad handedness", "Grooves", "Cation"),
                  selected = "GBA"
                )
              ),
              tabsetPanel(
                tabPanel(
                  title = "Individual coordinates",
                  plotOutput(
                    "pca.cd.ids.coord.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Predictions",
                  plotOutput(
                    "predict.cd.ids.coord.2",
                    height = "800px"
                  )
                )
              )
            ),
            shinydashboardPlus::box(
              title = "PCA analytics 1",
              collapsible = TRUE,
              width = 6,
              tabsetPanel(
                tabPanel(
                  title = "Data table",
                  DTOutput("pca.cd.ids.table")
                ),
                tabPanel(
                  title = "Scree",
                  plotOutput(
                    "pca.cd.ids.scree",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Factor map",
                  plotOutput(
                    "pca.cd.ids.fac.map",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Correlation circle",
                  plotOutput(
                    "pca.cd.ids.var.cor",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Variable contributions",
                  plotOutput(
                    "pca.cd.ids.var.coord",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Total within sum of squares",
                  plotOutput(
                    "pca.cd.ids.twss",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Gap statistic",
                  plotOutput(
                    "pca.cd.ids.gap",
                    height = "800px"
                  )
                )
              )
            ),
            shinydashboardPlus::box(
              title = "PCA analytics 1",
              collapsible = TRUE,
              width = 6,
              tabsetPanel(
                tabPanel(
                  title = "Scree",
                  plotOutput(
                    "pca.cd.ids.scree.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Factor map",
                  plotOutput(
                    "pca.cd.ids.fac.map.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Correlation circle",
                  plotOutput(
                    "pca.cd.ids.var.cor.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Variable contributions",
                  plotOutput(
                    "pca.cd.ids.var.coord.2",
                    height = "800px"
                  )
                ),
                
                tabPanel(
                  title = "Total within sum of squares",
                  plotOutput(
                    "pca.cd.ids.twss.2",
                    height = "800px"
                  )
                ),
                tabPanel(
                  title = "Gap statistic",
                  plotOutput(
                    "pca.cd.ids.gap.2",
                    height = "800px"
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)









