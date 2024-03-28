/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM PortfolioProject..NashvilleHousing


-- Standardize Date Format
	--remove time
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing

	--Update
UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate) -- may be its not working


	-- Add New column 
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;
	-- SET Updated Data to the new column
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted
FROM PortfolioProject..NashvilleHousing --DONE

------------------------------------------------------------------

-- Populate Property Addres data

SELECT *
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL 
ORDER BY ParcelID


-- IF Two ParcelID is SAME SO the PropetyAddress is SAME too -JOIN with ParcelID-
SELECT *
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ] --to avoid dublicated data through the JOIN statement 

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress) -- If first Arg IS NUll SO SET It's Data from second Arg
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- UPDATE 
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress) 
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- CHECK
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress 
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NOT NULL


------------------------------------------------------------------
 
 -- Breaking out Address into Individual Columns (Address, City, State)
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID


SELECT	--string_expression, start,	lenght => trim from delimiter
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address --SUBSTRING(string_expression, start, length)
				--CHARINDEX(substring (delimiter), string_expression (-1 to remove comma))
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID



SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address, 
--					string					start								END
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS CITY --the comma is ignored
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID

-- CAN'T SEPARATE one column to two columns without creating two other columns
--CREATE two columns
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress VARCHAR(255),
	PropertySplitCity VARCHAR(255);
-- SET Valus in new columns
UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject..NashvilleHousing



------------------ OwnerAddress  (parse name)
-- 
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing
SELECT PropertyAddress   -- hasn't a state
FROM PortfolioProject..NashvilleHousing


--PARSENAME used for split the string according to '.'     
--SO we 've to REPLACE the ',' to '.'
SELECT
REPLACE(OwnerAddress, ',', '.') 
FROM PortfolioProject..NashvilleHousing

--PARSENAME
SELECT							         --order of '.' reversed 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Adress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM PortfolioProject..NashvilleHousing

--ADD COLUMNS
ALTER TABLE  PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255),
	OwnerSplitCity NVARCHAR(255),
	OwnerSplitState NVARCHAR(255)



--SET VALUES
UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) 
	
--------------------------------------------------------------------------------

--Change Y and N to Yes and No in "Solid as Vacant" field

--Data Overview
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--Change Y => Yes   N => No
SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END 
FROM PortfolioProject..NashvilleHousing

--SET Values
UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END 

------------------------------------------------

-- Remove Dublicates  -order rank  -row number      
--if all columns are the same so the row is dublicate


SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID

--using CTE to reuse row_num

WITH RowNumCTE AS (
SELECT *,					-- To Know how many dublicate of each row
	ROW_NUMBER() OVER(
		PARTITION BY ParcelID, 
					PropertyAddress, 
					SalePrice,
					SaleDate, 
					LegalReference
					ORDER BY 
						UniqueID ) row_num

FROM PortfolioProject..NashvilleHousing
)


SELECT *
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY ParcelID

-- TO Delete Every dublicate run DELETE
DELETE
FROM RowNumCTE
WHERE row_num > 1 

---------------------------------------------------------------

-- DROP Unused Columns

SELECT *
FROM PortfolioProject..NashvilleHousing

-- Let's Drop OwnerAddress PropertyAddress TaxDistrict Column
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict



