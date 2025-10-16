-- Script to create managed identity users in Azure SQL Database
-- Run this script AFTER Terraform deployment completes
-- Connect to the database using Azure AD authentication as the admin user

-- Instructions:
-- 1. Get the backend app's managed identity name from Terraform outputs
-- 2. Connect to SQL Database using Azure AD auth (not SQL auth)
-- 3. Run this script, replacing <BACKEND_APP_NAME> with actual app name

-- Create user for backend app's managed identity
-- Replace backend-rg-myapp-cde-0 with your actual backend app name
CREATE USER [backend-rg-myapp-cde-0] FROM EXTERNAL PROVIDER;

-- Grant minimal required permissions (db_datareader and db_datawriter)
ALTER ROLE db_datareader ADD MEMBER [backend-rg-myapp-cde-0];
ALTER ROLE db_datawriter ADD MEMBER [backend-rg-myapp-cde-0];

-- Optional: Grant additional permissions if needed
-- ALTER ROLE db_ddladmin ADD MEMBER [backend-rg-myapp-cde-0];  -- For schema changes

-- Verify the user was created
SELECT name, type_desc, authentication_type_desc 
FROM sys.database_principals 
WHERE name = 'backend-rg-myapp-cde-0';

-- To get the exact app name, run this query from your terminal:
-- az webapp list --resource-group rg-myapp-cde --query "[?contains(name,'backend')].name" -o tsv

-- Alternative: Create user for frontend (if it needs direct DB access - not recommended)
-- CREATE USER [frontend-rg-myapp-cde-0] FROM EXTERNAL PROVIDER;
-- ALTER ROLE db_datareader ADD MEMBER [frontend-rg-myapp-cde-0];

/*
SECURITY NOTES:
- Backend app has read/write access to support API operations
- Frontend app typically shouldn't have direct DB access (goes through backend API)
- This uses Azure AD authentication - no passwords or connection strings needed
- App uses "Authentication=Active Directory Default" in connection string
- Managed identity automatically authenticates when app connects to SQL
*/
