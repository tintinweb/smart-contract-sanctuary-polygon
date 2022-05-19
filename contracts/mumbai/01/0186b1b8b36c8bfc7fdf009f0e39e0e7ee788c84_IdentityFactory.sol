/**
 *Submitted for verification at polygonscan.com on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
    function transfer(address _to, uint256 _value) external;

    function balanceOf(address _owner) external view returns (uint256 balance);
}

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function getApproved(uint256 _tokenId) external returns (address owner);
}

contract IdentityFactory {
    address[] private owners;
    mapping(address => bool) private isOwner;

    mapping(address => uint256) private equities;

    struct NFT {
        address sentBy;
        address collection;
        uint256 tokenId;
        uint256 sentAt;
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
            msg.sender,
            address(this),
            tokenId
        );
        NFT memory nft = NFT(msg.sender, nftCollection, tokenId, block.number);
        nfts.push(nft);
    }

    function hasNft(address nftCollection, uint256 tokenId)
        external
        view
        returns (bool, uint256)
    {
        // need to think about the case where the nft can be sent without using transferNFT() function
        // how do we find about the since then? or can we prevent sending it directly?
        // 

        bool doIHave = IERC721(nftCollection).ownerOf(tokenId) == address(this);
        uint256 since;

        for (uint256 i = 0; i < nfts.length; ++i) {
            if (
                nfts[i].collection == nftCollection &&
                nfts[i].tokenId == tokenId
            ) {
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
        // withdraws eth and ERC20 tokens balance according to the equities

        uint256 etherBal = address(this).balance;

        for (uint256 i = 0; i < owners.length; i++) {
            for (uint256 j = 0; j < acceptedTokens.length; j++) {
                IERC20(acceptedTokens[j]).transfer(
                    owners[i],
                    equities[owners[i]] *
                        IERC20(acceptedTokens[j]).balanceOf(address(this))
                );
            }

            payable(owners[i]).transfer(etherBal * equities[owners[i]]);
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
        delete nfts;
    }

    function destruct() public onlyOwners {
        // USE WITH CAUTION
        disintegrate();
        selfdestruct(payable(msg.sender));
    }

    // function disintegrateInit() public onlyOwners {
    //     // require message sender to be in owners array
    //     withdraw();
    // }

    // function disintegrateFinalize() public onlyOwners {
    //     // return all NFTs to original owner

    // }
}