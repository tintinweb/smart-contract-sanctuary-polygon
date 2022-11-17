// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface ICoffeeTradeTransparency {
    event AgreementCreated(bytes16 indexed uuid, string indexed buyerEnsAddress, string indexed sellerEnsAddress);

    event AgreementUpdated(bytes16 indexed uuid, string indexed buyerEnsAddress);

    event AgreementCancelled(bytes16 indexed uuid, string indexed buyerEnsAddress);

    event AgreementApprovedByBuyer(bytes16 indexed uuid, string indexed buyerEnsAddress);

    event AgreementApprovedBySeller(bytes16 indexed uuid, string indexed sellerEnsAddress);

    struct PurchaseAgreementParticulars {
        uint256 epochDate;
        uint64 commodityMicroPricePerUnit;
        uint64 fairTradeMicroPremiumPerUnit;
        uint8 purchasePriceMinMultiple;
        string refNum;
        string buyerEnsDomain;
        string sellerEnsDomain;
        string currencyIsoCode;
        string purchaseUnit;
        string purchaseTerms;
        string fairTradePriceSource;
        string commodityPriceSource;
        string metadataUri;
        string farm;
        string lot;
        string producer;
        string variety;
        string process;
        string altitude;
    }

    struct PurchaseAgreement {
        bytes16 uuid;
        bool isBuyerApproved;
        bool isSellerApproved;
        bool isCancelled;
        uint256 sellerApprovalTxFee;
        PurchaseAgreementParticulars particulars;
    }

    function findAgreementByUuid(bytes16 uuid) external view returns (PurchaseAgreement memory);

    function buyerCreateAgreement(
        bytes16 uuid,
        PurchaseAgreementParticulars memory agreementParticulars
    ) external payable;

    function buyerUpdateAgreement(bytes16 uuid, PurchaseAgreementParticulars memory agreementParticulars) external;

    function buyerCancelAgreement(bytes16 uuid) external;

    function buyerApproveAgreement(bytes16 uuid) external;

    function sellerApproveAgreement(bytes16 uuid) external;

    function withdrawContractEthBalance(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface ICompanyRegistry {
    struct Company {
        string name;
        string physicalAddress;
        string ensDomain;
        string website;
        address walletAddress;
        uint8 tradeRole;
        bool isEnabled;
    }

    function findCompanyByAddress(address companyAddress) external view returns (ICompanyRegistry.Company memory);

    function findCompanyByEns(string memory ensDomain) external view returns (ICompanyRegistry.Company memory);

    function registerCompany(Company calldata company) external;

    function updateCompany(Company calldata company) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "../interfaces/ICompanyRegistry.sol";
import "../interfaces/ICoffeeTradeTransparency.sol";

library CompanyHelper {
    uint8 constant TRADE_ROLE_BUYER = 1;
    uint8 constant TRADE_ROLE_SELLER = 2;

    function checkCompanyAddressExists(ICompanyRegistry.Company memory company) public pure {
        require(company.walletAddress != address(0), "Company with connected wallet address not found");
    }

    function checkIsCompanyAllowed(ICompanyRegistry.Company memory company) public pure {
        checkCompanyAddressExists(company);
        require(company.isEnabled == true, "Company not allowed");
    }

    function checkIsBuyerRole(ICompanyRegistry.Company memory company) public pure {
        checkIsCompanyAllowed(company);
        require(company.tradeRole == TRADE_ROLE_BUYER, "Unauthorized, company is not a Buyer");
    }

    function checkIsSellerRole(ICompanyRegistry.Company memory company) public pure {
        checkIsCompanyAllowed(company);
        require(company.tradeRole == TRADE_ROLE_SELLER, "Unauthorized, company is not a Seller");
    }

    function checkIsBuyerOnAgreement(
        ICompanyRegistry.Company memory company,
        ICompanyRegistry companyRegistry,
        ICoffeeTradeTransparency.PurchaseAgreement storage existingAgreement
    ) public view {
        checkIsBuyerRole(company);

        ICompanyRegistry.Company memory buyerOnAgreement = companyRegistry.findCompanyByEns(
            existingAgreement.particulars.buyerEnsDomain
        );

        require(
            company.walletAddress == buyerOnAgreement.walletAddress,
            "Unauthorized, company is not the buyer on agreement"
        );
    }

    function checkIsSellerOnAgreement(
        ICompanyRegistry.Company memory company,
        ICompanyRegistry companyRegistry,
        ICoffeeTradeTransparency.PurchaseAgreement memory existingAgreement
    ) public view {
        checkIsSellerRole(company);

        ICompanyRegistry.Company memory sellerOnAgreement = companyRegistry.findCompanyByEns(
            existingAgreement.particulars.sellerEnsDomain
        );

        require(
            company.walletAddress == sellerOnAgreement.walletAddress,
            "Unauthorized, company is not the seller on agreement"
        );
    }
}