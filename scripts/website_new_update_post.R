# New update post script.
# Run this script to add a new update post without writing R code.

library(here)
library(blogdown)

setwd(here("website"))

print("New update post script. ")
print("Type 'press' (or '1') for a new press update post and type 'project' (or '2') for a new project update post.")

correct_entry <- FALSE
press_post <- FALSE
project_post <- FALSE
while(correct_entry == FALSE) {
  new_post_type = readline("New post type: ")
  if(new_post_type == "press" || new_post_type == 1) {
    correct_entry <- TRUE
    press_post <- TRUE
  } else if(new_post_type == "project" || new_post_type == 2) {
    correct_entry <- TRUE
    project_post <- TRUE
  } else {
    print("Incorrect post type.")
  }
}

if(press_post == TRUE) {
  print("Enter a title for the new press update post.")
  post_title <- readline("Title: ")
  confirm <- FALSE
  while(confirm == FALSE) {
    print(post_title)
    answer <- readline("Is this okay? Type 'y' if yes or type 'n' if no: ")
    if(answer == "y") {
      confirm <- TRUE
      new_post(post_title, subdir = "press")
    } else if(answer == "n") {
      post_title <- readline("Title: ")
    }
  }
} else if(project_post == TRUE) {
  print("Enter a title for the new project update post.")
  post_title <- readline("Title: ")
  confirm <- FALSE
  while(confirm == FALSE) {
    print(post_title)
    answer <- readline("Is this okay? Type 'y' if yes or type 'n' if no: ")
    if(answer == "y") {
      confirm <- TRUE
      new_post(post_title, subdir = "projectupdates")
    } else if(answer == "n") {
      post_title <- readline("Title: ")
    }
  }
}
