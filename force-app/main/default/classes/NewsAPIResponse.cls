/**
 * Wrapper class for parsing the NewsAPI response
 */
public class NewsAPIResponse {
    // TODO: Define fields to match the NewsAPI response structure
    public String status { get; set; }
    public Integer totalResults { get; set; }
    public List<Article> articles { get; set; }
    
    /**
     * Inner class representing a news article
     */
    public class Article {
        // TODO: Define article fields
        public Source source;
        public String author;
        public String title;
        public String description;
        public String url;
        public String urlToImage;
        public Datetime publishedAt;
        public String content;
        /**
         * Converts the API article to a Salesforce Article__c record
         * @return Article__c The Salesforce record
         */
        public Article__c toSObject(Id categoryId, String categoryName) {
            // TODO: Implement conversion from API article to Salesforce record
            // Consider:
            // - Handling date conversion
            // - Generating a unique record name
            // - Handling field length limits
            Article__c a = new Article__c();
            a.Author__c = this.author;
            a.Content__c = this.content;
            a.Description__c = this.description;
            a.Published_At__c = this.publishedAt;
            a.Source__c = this.source.name;
            a.Title__c = this.title;
            a.Category__c = categoryName;
            a.News_Category__c = categoryId;
            a.URL__c = this.url;
            a.urlToImage__c = this.urlToImage != null && this.urlToImage.length() > 255 ? this.urlToImage.substring(0, 255) : this.urlToImage;

            String uniqueKey = (this.url != null ? this.url : this.title + String.valueOf(this.publishedAt));
            a.External_Id__c = uniqueKey.length() > 255 ? uniqueKey.substring(0, 255) : uniqueKey;

            
            String sourceCheck = this.source.name != null ? this.source.name : 'Unknown Source';
            String titleCheck = this.title != null ? this.title : 'Untitled';
            String concatTitle = sourceCheck + ' - ' + titleCheck;
            String articleName = concatTitle.length() > 80 ? concatTitle.substring(0, 80) : concatTitle;

            a.Name = articleName;

            
            return a;
        }
    }
    
    /**
     * Inner class representing a news source
     */
    public class Source {
        // TODO: Define source fields
        public String id;
        public String name;
    }
    
    /**
     * Helper method to convert all articles in this response to Salesforce records
     * @return List<Article__c> List of Salesforce records
     */
    public List<Article__c> toSObjects(Id categoryId, String categoryName) {
        // TODO: Implement conversion of all articles to Salesforce records
        List<Article__c> articlesList = new List<Article__c>();
        System.debug('***Converting articles to Article__c | Category: ' + categoryName + ', Count: ' + articles.size());
        for (Article article : articles) {
            articlesList.add(article.toSObject(categoryId, categoryName));
        }
        return articlesList;
    }
} 