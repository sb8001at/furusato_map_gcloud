library(tidyverse)
library(shiny)
library(sf)
library(shinythemes)
library(leaflet)

options(scipen=100) # 桁の大きい数値を指数表示にしない

vec <- 
  c("pop", "pop_M", "pop_F", "pop_2015", "pop_change", "pop_change_rate",
    "pop_density", "household", "Number_donations_accepted", "Donation_amount_accepted",
    "Number_donations_from_outside", "Donation_amount_from_outside", "Costs_procure_gifts",
    "Costs_return_gifts", "Costs_PR", "Costs_settlement", "Costs_Administration",
    "Costs_others", "Total_costs", "Donation_amount_per_pop", "Donation_number_per_pop")

names(vec) <- 
  c("人口（2020年）", "男性人口", "女性人口", "人口（2015年）", "5年間の人口増減数", 
    "5年間の人口増減率", "人口密度", "世帯数", "受け入れた寄付件数", "受け入れた寄附金額", 
    "市町村外から受け入れた寄付件数", "市町村外から受け入れた寄付金額", "返礼品等の調達に係る費用",
    "返礼品等の送付に係る費用", "広報に係る費用", "決済等に係る費用", "事務に係る費用", 
    "その他の費用", "費用合計", "一人当たりの市町村外から受け入れた寄付金額",
    "一人当たりの市町村外から受け入れた寄付件数")

vec_nin <- c("pop", "pop_M", "pop_F", "pop_2015", "pop_change", "pop_density")
vec_ken <- c("Number_donations_accepted", "Number_donations_from_outside", "Donation_number_per_pop")
vec_yen <- c(
  "Donation_amount_accepted", "Donation_amount_from_outside", "Costs_procure_gifts",
  "Costs_return_gifts", "Costs_PR", "Costs_settlement", "Costs_Administration",
  "Costs_others", "Total_costs", "Donation_amount_per_pop")

ui <- fluidPage(
    theme = shinytheme("united"),
    
    titlePanel("ふるさと納税データマップ"),
    
    tabsetPanel(
      tabPanel(
        "マップ",
        div(leafletOutput("leafletPlot", height="100%"), style = "height: 86vh"),
        
        absolutePanel(top = 120, right=20, 
                selectInput(
                  "year", "年度",
                  c("2017", "2018", "2019", "2020", "2021", "2022", "2023"), selected="2023"),
                
                selectInput(
                  "col_id", "表示する項目",
                  c("人口（2020年）", "男性人口", "女性人口", "人口（2015年）", "5年間の人口増減数", 
                    "5年間の人口増減率", "人口密度", "世帯数", "受け入れた寄付件数", "受け入れた寄附金額", 
                    "市町村外から受け入れた寄付件数", "市町村外から受け入れた寄付金額", "返礼品等の調達に係る費用",
                    "返礼品等の送付に係る費用", "広報に係る費用", "決済等に係る費用", "事務に係る費用", 
                    "その他の費用", "費用合計", "一人当たりの市町村外から受け入れた寄付金額",
                    "一人当たりの市町村外から受け入れた寄付件数"), selected="一人当たりの市町村外から受け入れた寄付金額", width="600px")
          ),
        
        tags$footer("一人あたりの値は2020年人口を利用して計算しているため、正確ではありません。")
      ),
        
      tabPanel(
        "参考文献等",
        br(),
        p("出典：調査項目を調べる－国勢調査（総務省）令和２年国勢調査 人口等基本集計　（主な内容：男女・年齢・配偶関係，世帯の構成，住居の状態，母子・父子世帯，国籍など）"),
        tags$a(href="https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200521&tstat=000001136464&cycle=0&tclass1=000001136466&tclass2val=0&metadata=1&data=1", "政府統計の総合窓口（e-Stat）該当ページ"),
        br(),
        br(),
        p("出典：国土交通省国土数値情報ダウンロードサイト 行政区域データ(2024年) 全国データ"),
        tags$a(href="https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-N03-2024.html", "国土数値情報ダウンロードサイト 該当ページ"),
        br(),
        br(),
        p("出典：総務省 ふるさと納税ポータルサイト 関連資料 受入額の実績等"),
        tags$a(href="https://www.soumu.go.jp/main_sosiki/jichi_zeisei/czaisei/czaisei_seido/furusato/archive/", "ふるさと納税ポータルサイト 該当ページ")
      )
    )
  )

server <- shinyServer(
    function(input, output, session) {

    output$leafletPlot <- renderLeaflet({
    
    geofile <- paste0("furusato", input$year, ".geojson")  
    
    geo <- st_read(geofile)

    geo <- geo |> filter(!st_is_empty(geo)) # geometryにemptyがあるとleafletで取り扱いできない
    
    col_selected <- vec[input$col_id]
    
    val <- geo[col_selected]  |> st_drop_geometry() |> unlist()
    
    if(col_selected %in% vec_nin){
      char_val <- 
        paste0(format(val, big.mark = ",", scientific = F) |> str_trim(), "人")
    } else if(col_selected %in% vec_ken){
      char_val <- 
        paste0(format(val |> round(2), big.mark = ",", scientific = F) |> str_trim(), "件")
    } else if(col_selected %in% vec_yen){
      char_val <- 
        paste0(format(val |> round(2), big.mark = ",", scientific = F) |> str_trim(), "円")
    } else if(col_selected == "pop_change_rate"){
      char_val <- 
        paste0(val |> round(2), "%")
    } else if(col_selected == "household"){
      char_val <- 
        paste0(format(val, big.mark = ",", scientific = F) |> str_trim(), "軒")
    }
    
    bins <- quantile(val |> na.omit(), probs=seq(0, 1, by=0.1)) |> round(5)
    pal <- colorBin("Spectral", domain = val, bins = bins, reverse=TRUE)
    
    geo |> 
      leaflet() |> 
      addProviderTiles(providers$OpenStreetMap) |> 
      setView(137.5, 37.5, zoom = 6) |> 
      addPolygons(
        fillColor = ~pal(val),
        weight = 1,
        opacity = 1,
        color = "white",
        dashArray = "3",
        fillOpacity = 0.5,
        highlightOptions = highlightOptions(
          weight = 5,
          color = "#666",
          dashArray = "",
          fillOpacity = 0.3,
          bringToFront = TRUE),
        label = map2_chr(geo$city, char_val, paste),
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto")) |> 
      addLegend(pal = pal, values = ~val, opacity = 0.7, title = names(vec)[input$col_id],
                position = "bottomright")
    })
  }
)

shinyApp(ui = ui, server = server)