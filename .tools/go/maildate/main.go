package main

import (
	"log"
	"net/mail"
	"os"
	"time"

	"github.com/jhillyerd/enmime"
)

func main() {
	part, err := enmime.ReadParts(os.Stdin)
	if err != nil {
		log.Fatal(err)
	}

	part.BreadthMatchAll(func(p *enmime.Part) bool {
		date, err := mail.Header(p.Header).Date()
		if err != nil {
			log.Fatal(err)
		}
		p.Header.Set("Date", date.Local().Format(time.RFC1123Z))
		return false
	})

	if err := part.Encode(os.Stdout); err != nil {
		log.Fatal(err)
	}
}
