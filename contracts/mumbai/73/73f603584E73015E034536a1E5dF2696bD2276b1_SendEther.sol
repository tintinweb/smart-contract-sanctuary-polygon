// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract VoiceToken {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
}

contract InvoiceSigner {
    function findInvoiceById(
        uint256 invoiceId
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            string memory,
            address,
            string memory
        )
    {}
}

contract SendEther {
    address public nftContractAddress;
    address public invoiceAddress;

    constructor(address _nftContractAddress, address _invoiceAddress) {
        nftContractAddress = _nftContractAddress;
        invoiceAddress = _invoiceAddress;
    }

    function sendViaCall(uint256 tokenId) public payable {
        InvoiceSigner obj0 = InvoiceSigner(invoiceAddress);
        VoiceToken obj = VoiceToken(nftContractAddress);
        (, , uint256 invoiceTotal, , , , ) = obj0.findInvoiceById(tokenId);
        address useradd = obj.ownerOf(tokenId);

        (bool sent, bytes memory data) = useradd.call{value: invoiceTotal}("");
        require(sent, "Failed to send Ether");
    }
}