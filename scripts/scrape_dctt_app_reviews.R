# This script scrapes DCTT applications, on Android and iOS, reviews from the
# Google Play Store and/or the Apple iOS App Store.
#
# Reviews/ratings of these applications are loaded dynamically and therefore
# require simulating the manual manipulation of the web pages. The Selenium
# program, and the RSelenium bindings, are used to facilitate this need.

# Imports
library(RSelenium)
library(here)

# Store review URL suffixes
play_store_suffix <- ("&showAllReviews=true")
app_store_suffix <- ("#see-all/reviews")

# Start the Selenium server and a Firefox client to manipulate
pre_driver <- rsDriver(browser = "firefox", port = 4444L, verbose = FALSE)
driver <- pre_driver[["client"]]
Sys.sleep(5)

# Open the csv file containing the app info
urls <- read.csv(here("data", "dctt_app_urls.csv"))

# Create lists for each platform
play_store_urls <- urls[, "Play_Store_URL"]
app_store_urls <- urls[, "App_Store_URL"]

# Create a data frame to hold all the app reviews
apps_df <- read.csv(
  text = "App_Name,Platform,Reviewer_Name,Review_Date,Review_Rating,Review_Comment", 
  colClasses = c("character", "character", "character", "character", "character", "character"))

# Iterate over the Play Store URLs
for(x in play_store_urls) {
  driver$open()
  
  new_url <- paste(x, play_store_suffix, sep = "")
  Sys.sleep(3)
  driver$navigate(new_url)
  Sys.sleep(3)
  
  reached_end <- FALSE
  page_height <- driver$executeScript(" return document.body.scrollHeight;")
  
  while(reached_end == FALSE) {
    driver$executeScript("window.scrollTo(0, document.body.scrollHeight);")
    
    Sys.sleep(2)
    
    height <- driver$executeScript(" return document.body.scrollHeight;")
    if(height[[1]] == page_height[[1]]) {
      more_button <- FALSE
      tryCatch({
        suppressMessages({
          more_button = driver$findElement("class", "PFAhAf")$isElementDisplayed()[[1]]
        })
      },
      error = function(e) {
        NA_character_
      }
      )
      
      if(more_button == FALSE) {
        reached_end = TRUE
      } else {
        # O0WRkf is the class name for the show more button
        driver$findElement("class", "O0WRkf")$clickElement()
        Sys.sleep(2)
      }
    } else {
      page_height = height
    }
  }
  
  # Get the app name from the page
  app_name_element <- driver$findElement(using = "css", value = "div.sIskre > c-wiz > h1.AHFaub > span")
  app_name <- (app_name_element$getElementText())[[1]]
  
  # Click all the "Show Review" buttons if they exist
  full_review_buttons <- driver$findElements(using = "class", value = "OzU4dc")
  for(x in full_review_buttons) {
    x$clickElement()
  }
  
  # Get names of reviewers
  names <- driver$findElements(using = "css", value = "div.bAhLNe.kx8XBd > span.X43Kjb")
  names_list <- vector()
  for(x in names) {
    names_list <- append(names_list, (x$getElementText())[[1]])
  }
  
  # Get the date of the reviews
  dates <- driver$findElements(using = "css", value = "div.bAhLNe.kx8XBd > div > span.p2TkOb")
  dates_list <- vector()
  for(x in dates) {
    dates_list <- append(dates_list, (x$getElementText())[[1]])
  }
  
  # Get the review rating
  ratings <- driver$findElements(using = "css", value = "span.nt2C1d > div.pf5lIe > div")
  ratings_list <- vector()
  for(x in ratings) {
    ratings_list <- append(ratings_list, (x$getElementAttribute("aria-label"))[[1]])
  }
  
  # Get the review comments
  reviews <- driver$findElements(using = "class", value = "UD7Dzf")
  reviews_list <- vector()
  for(x in reviews) {
    reviews_list <- append(reviews_list, (x$getElementText())[[1]])
  }
  
  # Get the length of one of the lists and create a platform and app name list
  # of the same length
  len = length(names_list)
  app_list <- vector()
  platform_list <- vector()
  for(i in 1:len) {
    app_list <- append(app_list, app_name)
    platform_list <- append(platform_list, "Android")
  }
  
  # Create a new data frame with the information scraped from this page
  page_df <- data.frame(App_Name = app_list, Platform = platform_list, 
                        Reviewer_Name = names_list, Review_Date = dates_list, 
                        Review_Rating = ratings_list, Review_Comment = reviews_list)
  
  # Merge this page's data frame with the universal one
  apps_df <<- merge(apps_df, page_df, all = TRUE)
  
  # Close the session
  driver$close()
}

# Iterate over the App Store URLs
for(x in app_store_urls) {
  driver$open()
  
  new_url <- paste(x, app_store_suffix, sep = "")
  Sys.sleep(3)
  driver$navigate(new_url)
  Sys.sleep(3)
  
  reached_end <- FALSE
  page_height <- driver$executeScript(" return document.body.scrollHeight;")
  
  while(reached_end == FALSE) {
    driver$executeScript("window.scrollTo(0, document.body.scrollHeight);")
    
    Sys.sleep(2)
    
    height <- driver$executeScript(" return document.body.scrollHeight;")
    if(height[[1]] == page_height[[1]]) {
      reached_end = TRUE
    } else {
      page_height = height
    }
  }
  
  # Get the name of the app from the page
  app_name_element <- driver$findElement(using = "css", value = "a.see-all-header__link.link")
  app_name <- (app_name_element$getElementText())[[1]]
  
  # Get the names of the reviewers
  names <- driver$findElements(using = "css", value = "span.we-truncate.we-truncate--single-line.ember-view.we-customer-review__user")
  names_list <- vector()
  for(x in names) {
    names_list <- append(names_list, (x$getElementText())[[1]])
  }
  
  # Get the dates of the reviews
  dates <- driver$findElements(using = "class", value = "we-customer-review__date")
  dates_list <- vector()
  for(x in dates) {
    dates_list <- append(dates_list, (x$getElementText())[[1]])
  }
  
  # Get the review ratings
  ratings <- driver$findElements(using = "css", value = "figure.we-star-rating.ember-view.we-customer-review__rating.we-star-rating--large")
  ratings_list <- vector()
  for(x in ratings) {
    ratings_list <- append(ratings_list, (x$getElementAttribute("aria-label"))[[1]])
  }
  
  # Get the review comments
  reviews <- driver$findElements(using = "css", value = "div.we-customer-review.lockup.ember-view > blockquote > div.we-clamp.ember-view")
  reviews_list <- vector()
  for(x in reviews) {
    text <- (x$getElementText())[[1]]
    a <- substr(text, 1, 2)
    b <- substr(text, 1, 5)
    if(a != "Hi" && b != "Hello") {
      reviews_list <- append(reviews_list, text)
    }
  }
  
  # Get the length of one of the lists and create a platform and app name list
  # of the same length
  len = length(names_list)
  app_list <- vector()
  platform_list <- vector()
  for(i in 1:len) {
    app_list <- append(app_list, app_name)
    platform_list <- append(platform_list, "iOS")
  }
  
  # Create a new data frame with the information scraped from this page
  page_df <- data.frame(App_Name = app_list, Platform = platform_list, 
                        Reviewer_Name = names_list, Review_Date = dates_list, 
                        Review_Rating = ratings_list, Review_Comment = reviews_list)
  
  # Merge this page's data frame with the universal one
  apps_df <<- merge(apps_df, page_df, all = TRUE)
  
  # Close the session
  driver$close()
}

# Write the reviews to a csv file
write.csv(apps_df, here("data", "dctt_app_reviews.csv"), row.names = FALSE)

# Close the Selenium session and server
driver$closeall()
driver$closeServer()

#temp
pid <- as.numeric(system("pidof java", intern = TRUE))
if(pid > 1) {
  command <- paste("kill", pid, sep = " ")
  system(command)
}

