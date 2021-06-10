package workshop

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strings"

	"cloud.google.com/go/storage"
)

type PubSubMessage struct {
	Data []byte `json:"data"`
}

type PubSubBody struct {
	Name   string `json:"name"`
	Bucket string `json:"bucket"`
}

func toBase64(b []byte) string {
	return base64.StdEncoding.EncodeToString(b)
}

func Workshop(ctx context.Context, m PubSubMessage) error {
	var bd PubSubBody

	json.Unmarshal(m.Data, &bd)

	client, _ := storage.NewClient(ctx)

	rc, _ := client.Bucket(bd.Bucket).Object(bd.Name).NewReader(ctx)

	defer rc.Close()
	// Read the entire file into a byte slice
	bytes, err := ioutil.ReadAll(rc)
	if err != nil {
		log.Fatal(err)
	}

	var base64Encoding string

	// Determine the content type of the image file
	mimeType := http.DetectContentType(bytes)

	// Prepend the appropriate URI scheme header depending
	// on the MIME type
	switch mimeType {
	case "image/jpeg":
		base64Encoding += "data:image/jpeg;base64,"
	case "image/png":
		base64Encoding += "data:image/png;base64,"
	}

	// Append the base64 encoded output
	base64Encoding += toBase64(bytes)

	obj := client.Bucket("ahus-demo-1-converted").Object(strings.Split(bd.Name, ".")[0])
	w := obj.NewWriter(ctx)

	fmt.Fprint(w, base64Encoding)

	w.Close()

	return nil
}
