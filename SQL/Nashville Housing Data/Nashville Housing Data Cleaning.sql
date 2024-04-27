SELECT *
FROM NashvilleHousing

-- Standardize Date Format

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate)

SELECT SaleDateConverted
FROM NashvilleHousing

-- Populate Property Address data

SELECT EmptyPA.ParcelID, EmptyPA.PropertyAddress, PopulatedPA.ParcelID, PopulatedPA.PropertyAddress,
	ISNULL(EmptyPA.PropertyAddress, PopulatedPA.PropertyAddress)
FROM NashvilleHousing AS EmptyPA
JOIN NashvilleHousing AS PopulatedPA
	ON EmptyPA.ParcelID = PopulatedPA.ParcelID
	AND EmptyPA.[UniqueID ] <> PopulatedPA.[UniqueID ]
WHERE EmptyPA.PropertyAddress IS NULL

UPDATE EmptyPA
SET PropertyAddress = ISNULL(EmptyPA.PropertyAddress, PopulatedPA.PropertyAddress)
FROM NashvilleHousing AS EmptyPA
JOIN NashvilleHousing AS PopulatedPA
	ON EmptyPA.ParcelID = PopulatedPA.ParcelID
	AND EmptyPA.[UniqueID ] <> PopulatedPA.[UniqueID ]
WHERE EmptyPA.PropertyAddress IS NULL

-- Breaking out Address into Individual Columns (Address, City, State)

--Property Address

SELECT PropertyAddress
FROM NashvilleHousing

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SplittedPropertyAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET SplittedPropertyAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) 

ALTER TABLE NashvilleHousing
ADD SplittedPropertyCity NVARCHAR(255)

UPDATE NashvilleHousing
SET SplittedPropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) 

-- Owner Address

SELECT OwnerAddress
FROM NashvilleHousing

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SplittedOwnerAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET SplittedOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD SplittedOwnerCity NVARCHAR(255)

UPDATE NashvilleHousing
SET SplittedOwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD SplittedOwnerState NVARCHAR(255)

UPDATE NashvilleHousing
SET SplittedOwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Change Y and N to Yes and No in "Sold as Vacant" Field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID,
										  PropertyAddress,
										  SalePrice,
										  SaleDate,
										  LegalReference
										  ORDER BY
											UniqueID) AS row_num
FROM NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- Delete Unused Columns

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict, SaleDate