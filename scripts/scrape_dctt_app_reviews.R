# This script scrapes DCTT applications, on Android and iOS, reviews from the
# Google Play Store and/or the Apple iOS App Store.
#
# Reviews/ratings of these applications are loaded dynamically and therefore
# require simulating the manual manipulation of the web pages. The Selenium
# program, and the RSelenium bindings, are used to facilitate this need.

# Imports
library(RSelenium)
library(here)

# Close the selenium server by killing the Java process
close_selenium <- function() {
  os_type <- .Platform$OS.type
  if(os_type == "unix") {
    pid <- as.numeric(system("pidof java", intern = TRUE))
    if(pid > 1) {
      command <- paste("kill -9", pid, sep = " ")
      system(command)
    }
  } else if(os_type == "windows") {
    command <- ("taskkill /f /t /im java.exe")
    system(command)
  }
}

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
  text = "App_Name,Platform,Reviewer_Name,Review_Date,Review_Rating,Review_Comment,Developer_Response", 
  colClasses = c("character", "character", "character", "character", "character", "character", "character"))

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
    d <- as.Date((x$getElementText())[[1]], format = "%B %d, %Y")
    d <- format(d, "%m/%d/%Y")
    d <- as.character(d)
    dates_list <- append(dates_list, d)
  }
  
  # Get the review rating
  ratings <- driver$findElements(using = "css", value = "span.nt2C1d > div.pf5lIe > div")
  ratings_list <- vector()
  for(x in ratings) {
    text <- (x$getElementAttribute("aria-label"))[[1]]
    text <- strsplit(text, " ")
    new_rating <- paste(text[[1]][2], text[[1]][4], text[[1]][5], "5", sep = " ")
    ratings_list <- append(ratings_list, new_rating)
  }
  
  # Get the review comments
  reviews <- driver$findElements(using = "css", value = "div.d15Mdf.bAhLNe")
  reviews_list <- vector()
  dev_responses <- vector()
  for(x in reviews) {
    # Get the entire comment block and split it into an array by newline characters
    review_components <- strsplit((x$getElementText())[[1]], "\n")
    
    # If the length is 5 or 6, there is no developer response and the review
    # comment is at the last index.
    # If the length is 7 or 8, there is a developer response which is at the
    # last index while the review comment is at 2 less than the last index.
    if(length(review_components[[1]]) == 5 || length(review_components[[1]]) == 6) {
      reviews_list <- append(reviews_list, review_components[[1]][length(review_components[[1]])])
      dev_responses <- append(dev_responses, "N/A")
    } else if(length(review_components[[1]]) == 7 || length(review_components[[1]]) == 8) {
      reviews_list <- append(reviews_list, review_components[[1]][length(review_components[[1]]) - 2])
      dev_responses <- append(dev_responses, review_components[[1]][length(review_components[[1]])])
    }
  }
  
  # Compare the length of some of the lists; if they are not the same length, there
  # was a major problem scraping the information and the program should quit.
  # Vectors of differing lengths cannot be added to a data frame.
  if(length(reviews_list) != length(names_list) || length(ratings_list) != length(dates_list)) {
    close_selenium()
    print("Error: did not scrape a consistent amount of information from the web page.")
    quit("no")
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
                        Review_Rating = ratings_list, Review_Comment = reviews_list, 
                        Developer_Response = dev_responses)
  
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
  reviews <- driver$findElements(using = "css", value = "div.we-customer-review.lockup.ember-view")
  reviews_list <- vector()
  dev_responses <- vector()
  for(x in reviews) {
    # Get the entire comment block and split it into an array by newline characters
    review_components <- strsplit((x$getElementText())[[1]], "\n")
    
    # The reviewer comment is always at index 5.
    # If the length is 8 or less than there is no developer response.
    # If the length is 9 or greater than there is a developer response at the
    # index of 1 less than the length.
    if(length(review_components[[1]]) <= 8) {
      reviews_list <- append(reviews_list, review_components[[1]][5])
      dev_responses <- append(dev_responses, "N/A")
    } else if(length(review_components[[1]]) >= 9) {
      reviews_list <- append(reviews_list, review_components[[1]][5])
      dev_responses <- append(dev_responses, review_components[[1]][length(review_components[[1]]) - 1])
    }
  }
  
  # Compare the length of some of the lists; if they are not the same length, there
  # was a major problem scraping the information and the program should quit.
  # Vectors of differing lengths cannot be added to a data frame.
  if(length(reviews_list) != length(names_list) || length(ratings_list) != length(dates_list)) {
    close_selenium()
    print("Error: did not scrape a consistent amount of information from the web page.")
    quit("no")
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
                        Review_Rating = ratings_list, Review_Comment = reviews_list, 
                        Developer_Response = dev_responses)
  
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

# Close the Selenium server if it doesn't above
close_selenium()
