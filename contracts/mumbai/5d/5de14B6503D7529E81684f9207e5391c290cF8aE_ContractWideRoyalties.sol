// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library _RoyaltiesErrorChecking {
    function validateParameters(address recipient, uint256 value)
        internal
        pure
    {
        require(
            value <= 10000,
            "ERC2981Royalties: Royalties can't exceed 100%."
        );
        require(
            value == 0 || recipient != address(0),
            "ERC2981Royalties: Can't send royalties to null address."
        );
    }
}

library ContractWideRoyalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    function setRoyalties(
        RoyaltyInfo storage rd,
        address recipient,
        uint256 value
    ) external {
        _RoyaltiesErrorChecking.validateParameters(recipient, value);
        rd.recipient = recipient;
        rd.amount = uint24(value);
    }

    function getRoyaltiesRecipient(RoyaltyInfo storage rd)
        external
        view
        returns (address)
    {
        return rd.recipient;
    }

    function getRoyalties(RoyaltyInfo storage rd, uint256 saleAmount)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = rd.recipient;
        royaltyAmount = (saleAmount * rd.amount) / 10000;
    }
}

library PerTokenRoyalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    struct RoyaltiesDisbursements {
        mapping(uint256 => RoyaltyInfo) schedule;
    }

    function setRoyalties(
        RoyaltiesDisbursements storage rd,
        uint256 tokenId,
        address recipient,
        uint256 value
    ) external {
        _RoyaltiesErrorChecking.validateParameters(recipient, value);
        rd.schedule[tokenId] = RoyaltyInfo(recipient, uint24(value));
    }

    function getRoyalties(
        RoyaltiesDisbursements storage rd,
        uint256 tokenId,
        uint256 saleAmount
    ) public view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royaltyInfo = rd.schedule[tokenId];
        receiver = royaltyInfo.recipient;
        royaltyAmount = (saleAmount * royaltyInfo.amount) / 10000;
    }
}