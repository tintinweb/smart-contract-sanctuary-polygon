// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IdentityFactory.sol";

contract Identities {
    function createNewIdentity(address[] memory _owners, uint256[] memory _equities) public returns (address) {
        IdentityFactory identity = new IdentityFactory(_owners, _equities);

        return address(identity);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC20 {
    function transfer(address _to, uint256 _value) external;

    function balanceOf(address _owner) external view returns (uint256 balance);
}

interface IERC721 {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function getApproved(uint256 _tokenId) external returns (address owner);
}

// Extends ERC721 receiver contract
contract IdentityFactory is IERC721Receiver {
    address[] public owners;
    mapping(address => bool) public isOwner;

    mapping(address => uint256) public equities; // percentage of equity

    struct NFT {
        address sentBy; // original owner of the nft
        address collection;
        uint256 tokenId;
        uint256 sentAt; // block number at which nft is sent
    }

    NFT[] public nfts;
    address[] public acceptedTokens;

    constructor(address[] memory _owners, uint256[] memory _equities) {
        owners = _owners;
        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
            equities[_owners[i]] = _equities[i];
        }
    }

    modifier onlyOwners() {
        require(isOwner[msg.sender] == true, "not a owner");
        _;
    }

    function transferNFT(address nftCollection, uint256 tokenId)
        external
        onlyOwners
    {
        // requires approval before this call
        require(
            IERC721(nftCollection).getApproved(tokenId) == address(this),
            "contract not approved"
        );

        IERC721(nftCollection).safeTransferFrom(
            msg.sender, // from
            address(this), // to
            tokenId
        );

        // save transferred nft data for the record
        NFT memory nft = NFT(msg.sender, nftCollection, tokenId, block.number);
        nfts.push(nft);
    }

    function hasNft(address nftCollection, uint256 tokenId)
        external
        view
        returns (bool, uint256)
    {
        bool doIHave;
        uint256 since;

        for (uint256 i = 0; i < nfts.length; ++i) {
            if (
                nfts[i].collection == nftCollection &&
                nfts[i].tokenId == tokenId
            ) {
                doIHave = true;
                since = block.number - nfts[i].sentAt;
            }
        }

        return (doIHave, since);
    }

    function acceptErc20(address token) public onlyOwners {
        // Anyone can transfer ERC20 tokens or native token to the contract. Any owner can add the addresses of tokens that they're willing to accept
        acceptedTokens.push(token);
    }

    function withdraw() public onlyOwners {
        // withdraws NATIVE TOKEN and ERC20 tokens balance according to the equities

        uint256 etherBal = address(this).balance;

        for (uint256 i = 0; i < owners.length; i++) {
            payable(owners[i]).transfer((etherBal * equities[owners[i]]) / 100);
        }

        for (uint256 j = 0; j < acceptedTokens.length; j++) {
            uint256 erc20Bal = IERC20(acceptedTokens[j]).balanceOf(
                address(this)
            );

            for (uint256 i = 0; i < owners.length; i++) {
                IERC20(acceptedTokens[j]).transfer(
                    owners[i],
                    (erc20Bal * equities[owners[i]]) / 100
                );
            }
        }
    }

    function disintegrate() public onlyOwners {
        withdraw();
        for (uint256 i = 0; i < nfts.length; i++) {
            IERC721(nfts[i].collection).safeTransferFrom(
                address(this),
                nfts[i].sentBy,
                nfts[i].tokenId
            );
        }
        selfdestruct(payable(msg.sender));
    }

    receive() external payable {
        // receive ether
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}