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
        this.categoryId = categoryId;
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
        try {
            Integer pageSize = NewsAPIService.DEFAULT_PAGE_SIZE;
            System.debug('***[START] NewsCategoryQueueable | Category: ' + categoryName + ' | Page: ' + currentPage + '/' + pages);
            // Query the current category record
            News_Category__c category = [
                                        SELECT Id, Name, Sync__c 
                                        FROM News_Category__c 
                                        WHERE Id = :categoryId 
                                        LIMIT 1
            ];
            System.debug('***Retrieved category record: ' + category.Name + ' (Id: ' + categoryId + ')');
    
            // Call NewsAPI
            NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(categoryName, pageSize, currentPage);
            System.debug('***API call successful for page ' + currentPage + ', totalResults: ' + response.totalResults);

            // Convert API response to Article__c records
            List<Article__c> articlesToUpsert = response.toSObjects(categoryId, categoryName);
            System.debug('***Articles converted: ' + articlesToUpsert.size());
    
            // Insert or update articles using External ID
            if (!articlesToUpsert.isEmpty()) {
                System.debug('***Upserting articles for page ' + currentPage + '...');
                upsert articlesToUpsert External_Id__c;
            } else {
                System.debug('***No articles to upsert for page ' + currentPage);
            }
    
            // If this is the final page, update the category record
            if (currentPage == pages) {
                Integer totalPages = (Integer) Math.ceil(response.totalResults / (Decimal) pageSize);
    
                category.Pages__c = totalPages;
                category.Last_Synced__c = System.now();
                category.Sync__c = false;
                update category;
                System.debug('***Final page reached. Updated category: ' + category.Name + ' with totalPages = ' + totalPages);
            } else {
                //queue the next page
                Integer nextPage = currentPage + 1;
                System.debug('***Queueing next page: ' + nextPage + ' of ' + pages);
                System.enqueueJob(new NewsCategoryQueueable(
                    categoryId,
                    categoryName,
                    pages,
                    currentPage + 1
                ));
            }
            System.debug('***[COMPLETE] Page ' + currentPage + ' processed.');
        } catch (Exception ex) {
            System.debug('***Queueable failed for category: ' + categoryName + ' - ' + ex.getMessage());
        }
    }
} 