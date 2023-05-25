/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GelatoRentCollectorUtility {
    bytes32 private constant RENT_SHARE =
        bytes32(keccak256("TangibleRentShare"));
    bytes32 private constant TREASURY_TRACKER =
        bytes32(keccak256("TreasuryTracker"));

    function check(
        IAddressProvider ap,
        address realEstateContractAddress,
        uint256 timestamp
    ) external view returns (bool canExec, bytes memory callData) {
        (address rentShareAddress, address treasuryTrackerAddress) = abi.decode(
            ap.getAddresses(abi.encode(RENT_SHARE, TREASURY_TRACKER)),
            (address, address)
        );

        ITreasuryTracker treasuryTracker = ITreasuryTracker(
            treasuryTrackerAddress
        );
        IRentShare rentShare = IRentShare(rentShareAddress);

        (canExec, callData) = _checkTNFTs(
            treasuryTracker,
            rentShare,
            realEstateContractAddress,
            timestamp
        );
        if (!canExec) {
            (canExec, callData) = _checkFTNFTs(
                treasuryTracker,
                rentShare,
                realEstateContractAddress
            );
        }
    }

    function _checkTNFTs(
        ITreasuryTracker treasuryTracker,
        IRentShare rentShare,
        address realEstateContractAddress,
        uint256 timestamp
    ) internal view returns (bool canExec, bytes memory callData) {
        uint256 numTokens = treasuryTracker.tnftTokensInTreasurySize(
            realEstateContractAddress
        );

        if (numTokens > 0) {
            uint256 i = (timestamp / 60) % numTokens;

            // Get token ID and distributor address for each token
            uint256 tokenId = treasuryTracker.tnftTokensInTreasury(
                realEstateContractAddress,
                i
            );
            IDistributor distributor = rentShare.distributorForToken(
                realEstateContractAddress,
                tokenId
            );

            IRevenueShare revenueShare = distributor.rentShareContract();

            // If there is any claimable rent for the token, return a Web3 function call to collect the rent
            uint256 claimable = revenueShare.claimableForToken(
                realEstateContractAddress,
                tokenId
            );

            canExec = claimable > 0;
            if (canExec) {
                bytes memory data = abi.encodeWithSelector(
                    IRentCollector.collectRent.selector,
                    i,
                    0,
                    false
                );
                callData = abi.encodeWithSelector(
                    IRentCollector.execute.selector,
                    data
                );
            } else {
                callData = "0x";
            }
        }
    }

    function _checkFTNFTs(
        ITreasuryTracker treasuryTracker,
        IRentShare rentShare,
        address realEstateContractAddress
    ) internal view returns (bool canExec, bytes memory callData) {
        // Get the number of TNFT fractions in treasury for the real estate contract
        uint256 numFractions = treasuryTracker
            .tnftFractionContractsInTreasurySize(realEstateContractAddress);

        // Initialize an array to store function data for defractionalize transactions
        bool hasDefractionalizeTransaction;

        // Loop through all TNFT fractions in treasury
        for (uint256 j = 0; j < numFractions; j++) {
            // Get the address of the j-th TNFT fraction contract in treasury for the real estate contract
            address fractionContractAddress = treasuryTracker
                .tnftFractionsContracts(realEstateContractAddress, j);
            // Get all fraction tokens in treasury for the fraction contract
            uint256[] memory fractionTokenIds = treasuryTracker
                .getFractionTokensInTreasury(fractionContractAddress);
            // Create a Contract instance for the fraction contract
            IFractionalTNFT fraction = IFractionalTNFT(fractionContractAddress);

            // Check if there is only one fraction and that fraction has 100% share
            bool fullFraction = false;
            if (fractionTokenIds.length == 1) {
                uint256 tokenShare = fraction.fractionShares(
                    fractionTokenIds[0]
                );
                fullFraction = tokenShare == 100e5;
            }

            if (fractionTokenIds.length > 1 || fullFraction) {
                if (hasDefractionalizeTransaction == false) {
                    hasDefractionalizeTransaction = true;
                    callData = abi.encodeWithSelector(
                        IRentCollector.execute.selector,
                        abi.encodeWithSelector(
                            IRentCollector.defractionalize.selector,
                            fractionContractAddress,
                            fractionTokenIds
                        )
                    );
                }
            }

            // Get the TNFT contract address and token ID for the fraction
            address contractAddress = fraction.tnft();
            uint256 tokenId = fraction.tnftTokenId();

            // Get the distributor address for the TNFT token
            IDistributor distributor = rentShare.distributorForToken(
                contractAddress,
                tokenId
            );

            // Get the rent share contract address for the distributor
            IRevenueShare revenueShare = distributor.rentShareContract();

            // Loop through all fraction tokens in treasury for the fraction contract
            uint256 numFractionTokenIds = fractionTokenIds.length;
            for (uint256 k = 0; k < numFractionTokenIds; k++) {
                // Retrieve the amount of rent that is claimable for the current fraction token
                uint256 claimable = revenueShare.claimableForToken(
                    fractionContractAddress,
                    fractionTokenIds[k]
                );

                // If there is any claimable rent for the token, return a Web3 function call to collect the rent
                if (claimable > 0) {
                    canExec = true;
                    callData = abi.encodeWithSelector(
                        IRentCollector.execute.selector,
                        abi.encodeWithSelector(
                            IRentCollector.collectRent.selector,
                            j,
                            k,
                            true
                        )
                    );
                    return (canExec, callData);
                }
            }
        }

        // If there are defractionalize transactions in the array, return a Web3 function call to execute the first one
        if (hasDefractionalizeTransaction) {
            canExec = true;
        } else {
            canExec = false;
            callData = "0x";
        }
    }
}

interface IAddressProvider {
    function getAddresses(bytes calldata) external view returns (bytes memory);
}

interface IRevenueShare {
    function claimableForToken(address, uint256)
        external
        view
        returns (uint256);
}

interface IDistributor {
    function rentShareContract() external view returns (IRevenueShare);
}

interface IRentShare {
    function distributorForToken(address, uint256)
        external
        view
        returns (IDistributor);
}

interface ITreasuryTracker {
    function tnftTokensInTreasurySize(address) external view returns (uint256);

    function tnftTokensInTreasury(address, uint256)
        external
        view
        returns (uint256);

    function tnftFractionContractsInTreasurySize(address)
        external
        view
        returns (uint256);

    function tnftFractionsContracts(address, uint256)
        external
        view
        returns (address);

    function getFractionTokensInTreasury(address ftnft)
        external
        view
        returns (uint256[] memory);
}

interface IRentCollector {
    function execute(bytes memory) external;

    function collectRent(
        uint256,
        uint256,
        bool
    ) external;

    function defractionalize(address, uint256[] memory) external;
}

interface IFractionalTNFT {
    function fractionShares(uint256) external view returns (uint256);

    function tnft() external view returns (address);

    function tnftTokenId() external view returns (uint256);
}