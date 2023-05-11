/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File contracts/utils/IAppraisalBureauPrices.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAppraisalBureauPrices {
    /**
     * @notice This struct represents the different kinds of valuations available for appraisal.
     *
     * @params FineArt - Valuation for traditional fine art pieces.
     * @params DigitalArt - Valuation for NFTs art pieces.
     */
    enum ValuationKind {FineArt, DigitalArt}

    /**
     * @notice Enum that defines different report frequencies
     *
     * @param Weekly - Expiry of one week
     * @param Monthly - Expiry of one month
     * @param Quarterly - Expiry of three months
     */
    enum ReportFrequency {Weekly, Monthly, Quarterly}

    function getPrice(ValuationKind _kind, uint256 _artists, uint256 _pieces) external view returns (uint256);

    function getExpiry(ReportFrequency frequency) external returns (uint256);
}


// File contracts/utils/AppraisalBureauPrices.sol


pragma solidity ^0.8.17;

contract AppraisalBureauPrices is IAppraisalBureauPrices {
    uint256 private constant FINE_ART_BASE_PRICE = 1000;
    uint256 private constant FINE_ART_EXTRA_ARTIST_PRICE = 600;
    uint256 private constant FINE_ART_EXTRA_ARTWORK_PRICE = 300;

    uint256[3] private DIGITAL_ART_PRICES = [100, 90, 80];
    uint256[3] private DIGITAL_ART_LIMITS = [50, 100, type(uint256).max];

    function getPrice(ValuationKind kind, uint256 artists, uint256 pieces) external view returns (uint256) {
        if (kind == ValuationKind.FineArt) {
            return FINE_ART_BASE_PRICE +
            (artists - 1) * FINE_ART_EXTRA_ARTIST_PRICE +
            (pieces - artists) * FINE_ART_EXTRA_ARTWORK_PRICE;
        } else if (kind == ValuationKind.DigitalArt) {
            uint256 totalPrice = 0;
            for (uint256 i = 0; i < pieces; i++) {
                for (uint256 j = 0; j < 3; j++) {
                    if (i < DIGITAL_ART_LIMITS[j]) {
                        totalPrice += DIGITAL_ART_PRICES[j];
                        break;
                    }
                }
            }
            return totalPrice;
        } else {
            revert("Invalid ValuationKind");
        }
    }

    function getExpiry(ReportFrequency frequency) external view returns (uint256) {
        uint256 expiry;
        if (frequency == ReportFrequency.Weekly) {
            expiry = block.timestamp + 1 weeks;
        } else if (frequency == ReportFrequency.Monthly) {
            expiry = block.timestamp + 4 weeks;
        } else if (frequency == ReportFrequency.Quarterly) {
            expiry = block.timestamp + 13 weeks;
        }
        return expiry;
    }
}