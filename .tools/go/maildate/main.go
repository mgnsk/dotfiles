package main

import (
	"bytes"
	"io"
	"log"
	"mime/quotedprintable"
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

	var b bytes.Buffer
	if err := part.Encode(&b); err != nil {
		log.Fatal(err)
	}

	m := bytes.ReplaceAll(b.Bytes(), []byte("\r\n"), []byte("\n"))
	// unbreak the quoted linebreaks.
	r := quotedprintable.NewReader(bytes.NewReader(m))
	if _, err := io.Copy(os.Stdout, r); err != nil {
		log.Fatal(err)
	}
}
