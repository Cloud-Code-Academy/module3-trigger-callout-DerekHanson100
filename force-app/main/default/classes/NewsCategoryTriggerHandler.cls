/**
 * Handler class for NewsCategoryTrigger
 */
public with sharing class NewsCategoryTriggerHandler {
    
    /**
     * Handles after insert events for News_Category__c
     * Uses Future method for callouts when Sync__c is true
     * @param newRecords List of newly inserted News_Category__c records
     */
    public static void handleInsert(List<News_Category__c> newRecords) {
        // TODO: Implement insert handler
        // - Filter categories that need to be synced
        // - Call future method for callouts
        List<Id> categoriesToSync = new List<Id>();

        for (News_Category__c cat : newRecords) {
            if (cat.Sync__c == true && cat.Name != null) {
                categoriesToSync.add(cat.Id);
            }
        }

        if (!categoriesToSync.isEmpty()) {
            syncCategoriesWithFuture(categoriesToSync);
        }
    }
    
    /**
     * Handles after update events for News_Category__c
     * Uses Queueable Apex for callouts when Sync__c is true
     * @param newRecords List of updated News_Category__c records
     * @param oldMap Map of old record states
     */
    public static void handleUpdate(List<News_Category__c> newRecords, Map<Id, News_Category__c> oldMap) {
        // TODO: Implement update handler
        // - Filter categories that need to be synced
        // - Call queueable method for callouts
        List<News_Category__c> categoriesToSync = new List<News_Category__c>();

        for (News_Category__c cat : newRecords) {
            News_Category__c oldCat = oldMap.get(cat.Id);
    
            // Only run if Sync__c changed from false → true
            if (!oldCat.Sync__c && cat.Sync__c == true && cat.Name != null && cat.Pages__c != null) {
                categoriesToSync.add(cat);
            }
        }
    
        if (!categoriesToSync.isEmpty()) {
            syncCategoriesWithQueueable(categoriesToSync);
        }
    }
    
    /**
     * Future method to sync categories using the NewsAPI
     * Used for insert operations
     * @param categoryNames List of category names to sync
     */
    @future(callout=true)
    public static void syncCategoriesWithFuture(List<Id> categoryIds) {
        // TODO: Implement future method
        // - Get categories by name
        // - Make callouts to NewsAPI for each category
        // - Insert retrieved articles
        // - Update categories with last synced date
        System.debug('***[START] syncCategoriesWithFuture | Total IDs to process: ' + categoryIds.size());

        Map<Id, News_Category__c> categoriesById = new Map<Id, News_Category__c>(
                                                                                [SELECT Id, Name   
                                                                                FROM News_Category__c 
                                                                                WHERE Id 
                                                                                IN :categoryIds]
        );

        List<Article__c> allArticles = new List<Article__c>();
        List<News_Category__c> categoriesToUpdate = new List<News_Category__c>();


        for (Id categoryId : categoryIds) {
            try {
                if (!categoriesById.containsKey(categoryId)) {
                    System.debug('***Category not found for Id: ' + categoryId);
                    continue;
                }
    
                News_Category__c categoryRecord = categoriesById.get(categoryId);
                String categoryName = categoryRecord.Name;
                System.debug('***Processing category: ' + categoryName + ' (Id: ' + categoryId + ')');

                //calculate total pages
                Integer pageSize = NewsAPIService.DEFAULT_PAGE_SIZE;
                NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(categoryName, pageSize, 1);
                System.debug('***API call successful for ' + categoryName + ', totalResults: ' + response.totalResults);
                Integer totalPages = (Integer) Math.ceil(response.totalResults / (Decimal) pageSize);
                categoryRecord.Pages__c = totalPages;

                List<Article__c> articles = response.toSObjects(categoryRecord.Id, categoryName);
    
                allArticles.addAll(articles);
                System.debug('***Articles converted: ' + articles.size());
                //Update the News_Category__c record
                // categoryRecord.Last_Synced__c = System.now();
                categoryRecord.Sync__c = false;
                update categoryRecord;

                categoryRecord.Sync__c = true;
                update categoryRecord;
    
            } catch (Exception ex) {
                System.debug('***Failed syncing category: ' + categoryId + ' - ' + ex.getMessage());
            }
        }
        if (!allArticles.isEmpty()) {
            System.debug('***Upserting ' + allArticles.size() + ' articles...');
            upsert allArticles External_Id__c;
        } else {
            System.debug('***No articles to upsert.');
        }
    
        if (!categoriesToUpdate.isEmpty()) {
            System.debug('***Updating ' + categoriesToUpdate.size() + ' News_Category__c records...');
            update categoriesToUpdate;
        } else {
            System.debug('***No category records to update.');
        }
        System.debug('***[COMPLETE] syncCategoriesWithFuture');
    }
    
    /**
     * Queueable method to sync categories using the NewsAPI
     * Used for update operations
     * @param categoriesToSync List of News_Category__c records to sync
     */
    private static void syncCategoriesWithQueueable(List<News_Category__c> categoriesToSync) {
        // TODO: Implement queueable job enqueuing
        // - Determine pages to sync for each category
        // - Create and enqueue NewsCategoryQueueable job for each category
        for (News_Category__c cat : categoriesToSync) {
            System.enqueueJob(new NewsCategoryQueueable(
                cat.Id,
                cat.Name,
                Integer.valueOf(cat.Pages__c)
            ));
        }
    }
    
} 