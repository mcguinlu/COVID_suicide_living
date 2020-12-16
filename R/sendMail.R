
sendMail <- function(sender, recepient, subject, content, cc=NULL){
  current_date <- format(Sys.time(), "%d-%m-%Y")
  
  email <- envelope() %>% 
    from(sender[1]) %>%
    to(recepient) %>%
    subject(subject) %>%
    html(sprintf("<p>Dear Julian,</p><br /><br /><p>Below are the update for the LSR on the impact of Covid-19 on Suicide attempts as of today %s: </p><br /><br />
         <p><b>Total found today</b>: <strong>%s</strong>
        <br /><b>Total awaiting initial decision</b>: <strong>%s</strong></p><br /><br /><p>BW<br />Covid_Suicide_LSR Team</p>",current_date, content[2], content[1]))
  
  smtp <- server(host = "smtp.gmail.com",
                 port = 587,
                 username = sender[1],
                 password = sender[2],
                 reuse = FALSE)
  
  smtp(email, verbose = FALSE)
  
  return (TRUE)
}
