/**
 * Queueable Apex class for processing News Category records with pagination support
 */
public class NewsCategoryQueueable implements Queueable, Database.AllowsCallouts {
    private Id categoryId;
    private String categoryName;
    private Integer pages;
    private Integer currentPage;
    
    /**
     * Constructor
     * @param categoryId The Id of the News_Category__c record
     * @param categoryName The category name
     * @param pages Total pages to sync
     */
    public NewsCategoryQueueable(Id categoryId, String categoryName, Integer pages) {
        // TODO: Initialize first page
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.pages = pages;
        this.currentPage = 1;
    }
    
    /**
     * Constructor with current page
     * @param categoryId The Id of the News_Category__c record
     * @param categoryName The category name
     * @param pages Total pages to sync
     * @param currentPage Current page being processed
     */
    public NewsCategoryQueueable(Id categoryId, String categoryName, Integer pages, Integer currentPage) {
        // TODO: Initialize with specific page
        this.categoryName = categoryName;
        this.currentPage = currentPage;
        this.pages = pages;
    }
    
    /**
     * Execute method for the queueable job
     * @param context The QueueableContext
     */
    public void execute(QueueableContext context) {
        // TODO: Implement execute method
        // - Call NewsAPI for the current page
        // - Process and save articles
        // - Update category if last page
        // - Chain to next page if more pages exist
        News_Category__c category = [SELECT Id, Name, Sync__c FROM News_Category__c WHERE Id = :categoryId LIMIT 1];
        
        NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(categoryName, 20, currentPage);
        
        List<Article__c> articlesToInsert = response.toSObjects();
        if (!articlesToInsert.isEmpty()) {
            insert articlesToInsert;
        }
        
        if (currentPage == pages) {
            category.Last_Synced__c = System.now();
            category.Sync__c = false;
            category.Name = categoryName;
            update category;
        }
        
        
    }
} 