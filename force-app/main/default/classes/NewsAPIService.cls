/**
 * Service class to interact with the NewsAPI for fetching top headlines
 */
public with sharing class NewsAPIService {
    // TODO: Define API endpoint constants
    
    private static final String API_NAMED_CREDENTIAL = 'callout:NewsAPI'; //https://newsapi.org
    private static final String API_ENDPOINT = '/v2/top-headlines';
    //String endpoint = API_NAMED_CREDENTIAL + API_ENDPOINT;
    
    // TODO: Define default parameters
    public static final Integer DEFAULT_PAGE_SIZE = 20; 
    
    /**
     * Fetches top headlines for a specified category with pagination support
     * @param category The news category (business, entertainment, general, health, science, sports, technology)
     * @param pageSize Number of results per page (default: 20, max: 100)
     * @param page Page number for pagination
     * @return NewsAPIResponse The wrapper object containing the API response
     */
    public static NewsAPIResponse getTopHeadlinesByCategory(String category, Integer pageSize, Integer page) {
        // TODO: Implement method to fetch headlines by category
        // - Validate and set defaults for parameters
        // - Build the request URL
        // - Make the callout
        // - Parse and return the response
        if (pageSize == null) pageSize = DEFAULT_PAGE_SIZE;
        if (page == null) page = 1;

        try{
            String queryParams = '?category=' + category + '&pageSize=' + pageSize + '&page=' + page;
            String fullEndpoint = API_NAMED_CREDENTIAL + API_ENDPOINT + queryParams;
            System.debug('***Calling NewsAPI: ' + fullEndpoint);
            HttpResponse res = makeCallout(fullEndpoint);

            if (res.getStatusCode() != 200) {
                throw new NewsAPIException('Failed to fetch headlines: ' + res.getStatusCode() + ' - ' + res.getBody());
            }

            NewsAPIResponse response = parseResponse(res.getBody());
            System.debug('***API response parsed | status: ' + response.status + ', totalResults: ' + response.totalResults);
            return response;
            

        } catch (Exception ex) {
            System.debug('***NewsAPIService ERROR: ' + ex.getMessage());
            throw new NewsAPIException('News API call failed: ' + ex.getMessage());
        }

    }
    
    /**
     * Helper method to make the HTTP callout
     * @param endpoint The full URL with parameters
     * @return HttpResponse The HTTP response
     */
    private static HttpResponse makeCallout(String endpoint) {
        // TODO: Implement HTTP callout
        // - Create and configure HTTP request
        // - Make the callout
        // - Handle exceptions
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        
        Http http = new Http();
        HttpResponse res = http.send(req);    
        
        return res;
    }
    
    /**
     * Helper method to parse the JSON response
     * @param jsonResponse The JSON response string
     * @return NewsAPIResponse The parsed response object
     */
    private static NewsAPIResponse parseResponse(String jsonResponse) {
        // TODO: Implement JSON parsing
        // - Deserialize JSON to NewsAPIResponse
        // - Handle exceptions
        
        return (NewsAPIResponse) JSON.deserialize(jsonResponse, NewsAPIResponse.class);
    }
    
    /**
     * Custom exception class for NewsAPI errors
     */
    public class NewsAPIException extends Exception {}
} 