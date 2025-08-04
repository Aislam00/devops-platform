package terraform

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
)

type Client struct {
	BaseURL    string
	Token      string
	HTTPClient *http.Client
}

type WorkspaceRequest struct {
	Data WorkspaceData `json:"data"`
}

type WorkspaceData struct {
	Type       string              `json:"type"`
	Attributes WorkspaceAttributes `json:"attributes"`
}

type WorkspaceAttributes struct {
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
}

func NewClient(baseURL, token string) *Client {
	return &Client{
		BaseURL:    baseURL,
		Token:      token,
		HTTPClient: &http.Client{},
	}
}

func (c *Client) CreateWorkspace(orgName, workspaceName, description string) error {
	url := fmt.Sprintf("%s/api/v2/organizations/%s/workspaces", c.BaseURL, orgName)

	payload := WorkspaceRequest{
		Data: WorkspaceData{
			Type: "workspaces",
			Attributes: WorkspaceAttributes{
				Name:        workspaceName,
				Description: description,
			},
		},
	}

	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal workspace request: %v", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonPayload))
	if err != nil {
		return fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("Content-Type", "application/vnd.api+json")
	req.Header.Set("Authorization", "Bearer "+c.Token)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to make request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		return fmt.Errorf("failed to create workspace, status: %d", resp.StatusCode)
	}

	return nil
}
