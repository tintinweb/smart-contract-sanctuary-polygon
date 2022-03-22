/**
 *Submitted for verification at polygonscan.com on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC721Like {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function awardItem(address player, string memory _tokenURI) external returns (uint256);
    function bundleItem(address player) external returns(uint256);
    function approveForMarket(address _owner, address _msgsender, address _operator, uint256 _tokenId) external;
    function setApproval(address _owner, address _operator, bool _approved) external;
    function tokenURI(uint256 tokenId) external returns (string memory);
    function ownerOf(uint256 tokenId) external returns (address);
    function hasFrozen(uint256 _tokenId) external view returns(bool);
    // function setFrozenURI(uint256 _tokenId, string memory _tokenUri) external returns(bool);
    // function getFrozenURI(uint256 _tokenId) external view returns(string memory);
}

library Strings {
    function isEqual(string memory num1, string memory num2) 
        internal pure returns(bool) {
            // 将string类型转为bytes类型进行比较
            bytes memory a = bytes(num1);
            bytes memory b = bytes(num2);

            // 比较长度
            if (a.length != b.length) {
                return false;
            }

            // 按位比较内容
            for(uint i = 0; i < a.length; i++) {
                if(a[i] != b[i]) {
                    return false;
                }
            }
            return true;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "you are not the owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract BaseMarket is Owned {
    address public nftAsset;   //资产部署地址
    address public revenueRecipient;  //平台受益人
    string public constant version = "2.0.5";
    uint public constant mintFee = 10 * 1e8;  //铸币费
    uint256 public constant transferFee = 5;  //交易权重值

    struct Bid {
        uint256 tokenID;
        address bidder;
        uint256 value;
    }

    struct Royalty {
        address originator;
        uint256 royalty;
        bool recommended;
        uint256 bundledID;
        string group;
    }

    struct Offer {
        bool isForSale;
        uint256 tokenID;
        address originator;
        address seller;
        address organization;
        bool isBid;
        bool isDonated;
        uint256 minValue;
        uint256 endTime;
        uint256 reward;
        string group;
    }
    // bundle sell捆绑销售
    struct BundleOffer {
        bool isForSale;
        uint256[] tokenIDs;
        address seller;
        address organization;
        bool isBid;
        bool isDonated;
        uint256 minValue;
        uint256 endTime;
        uint256 reward;
        string group;
    }

    event BidEntered(
        uint256 indexed tokenID,
        address fromAddress,
        uint256 value,
        bool indexed isBid,
        bool indexed isDonated
    );
    event Bought(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 indexed tokenID,
        uint256 value
    );
    event NoLongerForSale(uint256 indexed tokenID);
    event AuctionPass(uint256 indexed tokenID);
    event DealTransaction(
        uint256 indexed tokenID,
        bool indexed isDonated,
        address creator,
        address indexed seller
    );
    event Offered(
        uint256 indexed tokenID,
        bool indexed isBid,
        bool indexed isDonated,
        uint256 minValue
    );
    event BundleOffered(
        uint256[] indexed tokenIDs,
        bool indexed isBid,
        bool indexed isDonated,
        uint256 minValue,
        address seller
    );

    mapping(uint256 => Royalty) public royalty;
    // 受赠组织是否被认证
    mapping(address => bool) public isApprovedOrg;

    mapping(uint256 => Offer) public nftOfferedForSale;
    mapping(uint256 => Bid) public nftBids;
    mapping(uint256 => mapping(address => uint256)) public offerBalances;
    mapping(uint256 => address[]) public bidders;
    mapping(uint256 => mapping(address => bool)) public bade;
    // token资产是否被捆绑
    mapping(uint256 => bool) public isBundled;
    mapping(uint256 => BundleOffer) public nftBundledForSale;
    // 用户拥有的捆绑资产
    mapping(address => uint256[]) public bundledAssets;
    mapping(uint256 => mapping(address => bool)) public bundleBade;
    mapping(uint256 => Bid) public bundleBids;
    mapping(uint256 => address[]) public bundleBidders;
    mapping(uint256 => mapping(address => uint256)) public offerBundleBalances;

    // 创建collection
    using Strings for string;
    mapping(address => string[]) public groups;
    mapping(address => mapping(string => bool)) public isCreated;

    bool private _mutex;
    modifier _lock_() virtual {
        require(!_mutex, "reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    function newCollection(string memory _name) public _lock_ {
        require(!isCreated[msg.sender][_name], "This name of collection is already created");
        isCreated[msg.sender][_name] = true;
        groups[msg.sender].push(_name);
    }

    // approve the donated oraganizations认证受赠组织
    function approveOrganization(address _organization) public _lock_ {
        require(_organization != address(0), "organization is null");
        isApprovedOrg[_organization] = true;
    }

    constructor(address _nftAsset, address _revenueRecipient) {
        require(_nftAsset != address(0), "_nftAsset address cannot be 0");
        require(
            _revenueRecipient != address(0),
            "_revenueRecipient address cannot be 0"
        );
        nftAsset = _nftAsset;
        revenueRecipient = _revenueRecipient;
    }

    function NewNft(string memory _tokenURI, uint256 _royalty, string memory _group) external payable _lock_ returns (uint256)
    {
        require(_royalty < 30, "Excessive copyright fees");
        require(msg.value == mintFee, "The mintFee is 10 * 1e8");

        uint256 tokenID = ERC721Like(nftAsset).awardItem(msg.sender, _tokenURI);

        royalty[tokenID] = Royalty(msg.sender, _royalty, false, 0, _group);
        payable(revenueRecipient).transfer(mintFee);

        return tokenID;
    }

   // proxyMinter ==  revenueRecipient 平台受益人进行铸币
    function NewNFTByRevenueRecipient(string memory _tokenURI, 
        uint256 _royalty, string memory _group) external _lock_ returns(uint256)
    {
        require(_royalty < 30, "Excessive copyright fees");
    
        uint256 tokenID = ERC721Like(nftAsset).awardItem(msg.sender, _tokenURI);
        royalty[tokenID] = Royalty(msg.sender, _royalty, false, 0, _group);

        return tokenID;
    }

    function sell(
        uint256 tokenID,
        bool isBid,
        bool isDonated,
        uint256 minSalePrice,
        uint256 endTime,
        uint256 reward,
        address organization
    ) public _lock_ returns(uint256){
        if(isBid) {
            require(endTime <= block.timestamp + 30 days, "Maximum time exceeded");
            require(endTime > block.timestamp + 5 minutes, "Below minimum time");
        } 
        
        require(
            reward * 2 < 200 - transferFee - royalty[tokenID].royalty * 2,
            "Excessive reward"
        );
        ERC721Like(nftAsset).transferFrom(msg.sender, address(this), tokenID);
        
        //sell挂单
        if(isDonated) {
            nftOfferedForSale[tokenID] = Offer(
                true,
                tokenID,
                royalty[tokenID].originator,
                msg.sender,
                organization,
                isBid,
                isDonated,
                minSalePrice,
                endTime,
                reward,
                royalty[tokenID].group
            );
        } else {
            nftOfferedForSale[tokenID] = Offer(
                true,
                tokenID,
                royalty[tokenID].originator,
                msg.sender,
                address(0),
                isBid,
                isDonated,
                minSalePrice,
                endTime,
                reward,
                royalty[tokenID].group
            );
        }
        
        emit Offered(tokenID, isBid, isDonated, minSalePrice);
        return tokenID;
    }
    // 冻结资产信息
    // function freeze(uint256 tokenID, string memory _tokenUri) external _lock_ {
    //     require(!ERC721Like(nftAsset).hasFrozen(tokenID), "The nft is already been frozen");
    //     ERC721Like(nftAsset).setFrozenURI(tokenID, _tokenUri);
    // }

    function getTokenURI(uint256 tokenID) external _lock_ returns(string memory) {
        // if(ERC721Like(nftAsset).hasFrozen(tokenID)) {
        //     return ERC721Like(nftAsset).getFrozenURI(tokenID);
        // } else {
        //     return ERC721Like(nftAsset).tokenURI(tokenID);
        // }
        return ERC721Like(nftAsset).tokenURI(tokenID);
    }

    function buy(uint256 tokenID) external payable  _lock_{
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(!offer.isBid, "nft is auction mode");

        uint256 share1 = (offer.minValue * transferFee) / 200; //交易费
        uint256 share2 = (offer.minValue * royalty[tokenID].royalty) / 100;

        require(
            msg.value >= offer.minValue,
            "Sorry, your credit is running low"
        );
        
        payable(royalty[tokenID].originator).transfer(share2);
        if(offer.isDonated) {
            // 定价销售捐赠时，要将成交额的一部分返还版权税
            require(offer.organization != address(0), "The donated organization is null");
            require(isApprovedOrg[offer.organization], "the organization is not approved");
            payable(offer.organization).transfer(offer.minValue - share2);
        }else {
            payable(revenueRecipient).transfer(share1);
            payable(offer.seller).transfer(offer.minValue - share1 - share2);
        }
        
        ERC721Like(nftAsset).transferFrom(address(this), msg.sender, tokenID);
        
        emit Bought(
            offer.seller,
            msg.sender,
            tokenID,
            offer.minValue
        );
        delete nftOfferedForSale[tokenID];
    }

    function enterBidForNft(uint256 tokenID) external payable _lock_ 
    {
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(offer.isBid, "nft must beauction mode");
        require(block.timestamp < offer.endTime, "The auction is over");

        if (!bade[tokenID][msg.sender]) {
            bidders[tokenID].push(msg.sender);
            bade[tokenID][msg.sender] = true;
            
        }

        Bid memory bid = nftBids[tokenID];
        require(
            msg.value + offerBalances[tokenID][msg.sender] >=
                offer.minValue,
            "The bid cannot be lower than the starting price"
        );
        require(
            msg.value + offerBalances[tokenID][msg.sender] > bid.value,
            "This quotation is less than the current quotation"
        );
        nftBids[tokenID] = Bid(
            tokenID,
            msg.sender,
            msg.value + offerBalances[tokenID][msg.sender]
        );
        emit BidEntered(tokenID, msg.sender, msg.value, offer.isBid, offer.isDonated);
        offerBalances[tokenID][msg.sender] += msg.value;
    
    }

    //  deal for donation or not 拍卖成交订单
    function deal(uint256 tokenID) public _lock_ {
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(offer.isBid, "must be auction mode");
        require(offer.endTime < block.timestamp, "The auction is not over yet");

        Bid memory bid = nftBids[tokenID];

        if (bid.value >= offer.minValue) {
            uint256 share1 = (bid.value * transferFee) / 200;  //交易费
            uint256 share2 = (bid.value * royalty[tokenID].royalty) / 100;  //版权税
            uint256 share3 = 0;   //单笔bidders获益值
            uint256 totalBid = 0;  //总出价额

            for (uint256 i = 0; i < bidders[tokenID].length; i++) {
                if (bid.bidder != bidders[tokenID][i]) {
                    totalBid += offerBalances[tokenID][bidders[tokenID][i]];
                }
            }
            for (uint256 i = 0; i < bidders[tokenID].length; i++) {
                if (bid.bidder != bidders[tokenID][i]) {
                    uint256 tempC =
                        (bid.value *
                            offer.reward *
                            offerBalances[tokenID][bidders[tokenID][i]]) /
                            totalBid /
                            100;
                    payable(bidders[tokenID][i]).transfer(tempC);
                    share3 += tempC;
                    payable(bidders[tokenID][i]).transfer(
                        offerBalances[tokenID][bidders[tokenID][i]]
                    );
                    offerBalances[tokenID][bidders[tokenID][i]] = 0;
                    delete bade[tokenID][bidders[tokenID][i]];
                }
            }

            uint256 tempD = bid.value - share2 - share3;
            payable(royalty[tokenID].originator).transfer(share2);
            
            if(offer.isDonated) {
                // 拍卖销售捐赠时，成交额的一部分用于返还版权税和获益值
                require(offer.organization != address(0), "The donated organization is null");
                require(isApprovedOrg[offer.organization], "the organization is not approved");
                payable(offer.organization).transfer(tempD);
            }else {
                tempD = bid.value - share1 - share2 - share3;
                payable(revenueRecipient).transfer(share1);
                payable(offer.seller).transfer(tempD);
            }

            offerBalances[tokenID][bid.bidder] = 0;
            delete bade[tokenID][bid.bidder];
            delete bidders[tokenID];
            
            ERC721Like(nftAsset).transferFrom(
                address(this),
                bid.bidder,
                tokenID
            );
            
            emit DealTransaction(
                tokenID,
                offer.isDonated,
                royalty[tokenID].originator,
                offer.seller
            );
        } else {
            ERC721Like(nftAsset).transferFrom(
                address(this),
                offer.seller,
                tokenID
            );
            emit AuctionPass(tokenID);
        }    
        delete nftOfferedForSale[tokenID];
    }

    function bundleSell(
        bool isBid,
        bool isDonated,
        uint256[] memory tokenIDs,
        uint256 minSalePrice,
        uint256 endTime,
        uint256 reward,
        address organization
    ) public _lock_ returns(uint256){
        if(isBid) {
            require(endTime <= block.timestamp + 30 days, "Maximum time exceeded");
            require(endTime > block.timestamp + 5 minutes, "Below minimum time");
        } 

        // 判定是否允许捆绑的两个条件：卖方和collection是否相同
        address baseSeller = ERC721Like(nftAsset).ownerOf(tokenIDs[0]);
        string memory baseGroup = royalty[tokenIDs[0]].group;
        uint256 maxRoyalty = royalty[tokenIDs[0]].royalty;
        for(uint i = 0; i < tokenIDs.length; i++) {
            // require(ERC721Like(nftAsset).ownerOf(tokenIDs[0]) == baseSeller, "The seller of tokenIDs are not the same");
            // require(baseGroup.isEqual(royalty[tokenIDs[i]].group), "The group of tokenIDs are not the same");
            require(!isBundled[tokenIDs[i]], "The tokenID already could be bundled");
            isBundled[tokenIDs[i]] = true;

            if(royalty[tokenIDs[i]].royalty > maxRoyalty) {
                maxRoyalty = royalty[tokenIDs[i]].royalty;
            }
                // approve 授权资产
            ERC721Like(nftAsset).transferFrom(msg.sender, address(this), tokenIDs[i]);
        }

        require(
            //convert to integer operation 转变成整数的不等式
            reward * 2 < 200 - transferFee - maxRoyalty * 2,
            "Excessive reward"
        );
        // 获取捆绑资产的id
        uint256 newBundleId = ERC721Like(nftAsset).bundleItem(msg.sender);
        for(uint8 i = 0; i < tokenIDs.length; i++) {
            royalty[tokenIDs[i]].bundledID = newBundleId;
        }
        if(isDonated) {
            nftBundledForSale[newBundleId] = BundleOffer(
                true,
                tokenIDs,
                msg.sender,
                organization,
                isBid,
                isDonated,
                minSalePrice,
                endTime,
                reward,
                baseGroup
            );
        } else {
            nftBundledForSale[newBundleId] = BundleOffer(
                true,
                tokenIDs,
                msg.sender,
                address(0),
                isBid,
                isDonated,
                minSalePrice,
                endTime,
                reward,
                baseGroup
            );
        }
        bundledAssets[msg.sender].push(newBundleId);
        
        emit BundleOffered(tokenIDs, isBid, isDonated, minSalePrice, baseSeller);
        return newBundleId;
        
    }

    function buyBundle(uint256 tokenID) external payable _lock_{
        uint256 share1;  //交易费
        uint256 share2;  //版权税
        BundleOffer memory offer = nftBundledForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(!offer.isBid, "nft is auction mode");
        require(
            msg.value >= offer.minValue,
            "Sorry, your credit is running low"
        );
        
        // actually transaction transferfee 2.5%
        share1 = (offer.minValue * transferFee) / 200;

        uint i; //循环变量
        if(offer.isDonated) {
            require(offer.organization != address(0), "The donated organization is null");
            require(isApprovedOrg[offer.organization], "the organization is not approved");
            payable(offer.organization).transfer(offer.minValue);
            for(i = 0; i < offer.tokenIDs.length; i++) {
                isBundled[offer.tokenIDs[i]] = false;
                royalty[offer.tokenIDs[i]].bundledID = 0;
                ERC721Like(nftAsset).transferFrom(address(this), msg.sender, offer.tokenIDs[i]);
            }
        } else {
            uint256 total;
            payable(revenueRecipient).transfer(share1);
            for(i = 0; i < offer.tokenIDs.length; i++) {
                share2 = (offer.minValue * royalty[offer.tokenIDs[i]].royalty) / 100;
                total += share2;
                payable(royalty[offer.tokenIDs[i]].originator).transfer(share2);
                isBundled[offer.tokenIDs[i]] = false;
                royalty[offer.tokenIDs[i]].bundledID = 0;
                ERC721Like(nftAsset).transferFrom(address(this), msg.sender, offer.tokenIDs[i]);
            }
            payable(offer.seller).transfer(offer.minValue - share1 - total);
        }
        
        emit Bought(
            offer.seller,
            msg.sender,
            tokenID,
            offer.minValue
        );
            
        emit DealTransaction(
            tokenID,
            offer.isDonated,
            offer.seller,
            offer.seller
        );
        delete nftBundledForSale[tokenID];
    }

    function enterBidForBundle(uint256 tokenID) external payable _lock_ 
    {
        Bid memory bid = bundleBids[tokenID];
        BundleOffer memory offer = nftBundledForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(offer.isBid, "nft must beauction mode");
        require(block.timestamp < offer.endTime, "The auction is over");
        if(!bundleBade[tokenID][msg.sender]) {
            bundleBidders[tokenID].push(msg.sender);
            bundleBade[tokenID][msg.sender] = true;
        } 
        require(
            msg.value + offerBundleBalances[tokenID][msg.sender] >=
                offer.minValue,
            "The bid cannot be lower than the starting price"
        );
        require(
            msg.value + offerBundleBalances[tokenID][msg.sender] > bid.value,
            "This quotation is less than the current quotation"
        );
        bundleBids[tokenID] = Bid(
            tokenID,
            msg.sender,
            msg.value + offerBundleBalances[tokenID][msg.sender]
        );
        offerBundleBalances[tokenID][msg.sender] += msg.value;
    
        emit BidEntered(tokenID, msg.sender, msg.value, offer.isBid, offer.isDonated);
    }

    //  deal for donation or not
    function dealForBundle(uint256 tokenID) public _lock_{
        Bid memory bid = bundleBids[tokenID];
        BundleOffer memory offer = nftBundledForSale[tokenID];
        uint256 share1 = 0;  //交易费
        uint256 share2 = 0;  //版权税
        uint256 share3 = 0;  //单笔所有bidders的获益值
        uint256 total = 0;   //总出价值
        uint256 tempC = 0;   //单笔出价方的获益值
        uint256 i;  //循环变量

        require(offer.isForSale, "nft not actually for sale");
        require(offer.isBid, "must be auction mode");
        require(offer.endTime < block.timestamp, "The auction is not over yet");
    
        if (bid.value >= offer.minValue) {
            // actually transaction transferfee 2.5%
            share1 = (bid.value * transferFee) / 200;
    
            for (i = 0; i < bundleBidders[tokenID].length; i++) {
                if (bid.bidder != bundleBidders[tokenID][i]) {
                    total += offerBundleBalances[tokenID][bundleBidders[tokenID][i]];
                }
            }
            for (i = 0; i < bundleBidders[tokenID].length; i++) {
                if (bid.bidder != bundleBidders[tokenID][i]) {
                    tempC =
                        (bid.value *
                            offer.reward *
                            offerBundleBalances[tokenID][bundleBidders[tokenID][i]]) /
                            total /
                            100;
                    payable(bundleBidders[tokenID][i]).transfer(tempC);
                    share3 += tempC;
                    payable(bundleBidders[tokenID][i]).transfer(
                        offerBundleBalances[tokenID][bundleBidders[tokenID][i]]
                    );
                    offerBundleBalances[tokenID][bundleBidders[tokenID][i]] = 0;
                    delete bundleBade[tokenID][bundleBidders[tokenID][i]];
                }
            }
        
            if(offer.isDonated) {
                require(offer.organization != address(0), "The donated organization is null");
                require(isApprovedOrg[offer.organization], "the organization is not approved");
                payable(offer.organization).transfer(bid.value - share3);
                for(i = 0; i < offer.tokenIDs.length; i++) {
                    isBundled[offer.tokenIDs[i]] = false;
                    royalty[offer.tokenIDs[i]].bundledID = 0;
                    ERC721Like(nftAsset).transferFrom(address(this), bid.bidder, offer.tokenIDs[i]);
                }
                offerBundleBalances[tokenID][bid.bidder] = 0;
                delete bundleBade[tokenID][bid.bidder];
                delete bundleBids[tokenID];
            
            } else {
                total =0;
                payable(revenueRecipient).transfer(share1);
                for(i = 0; i < offer.tokenIDs.length; i++) {
                    isBundled[offer.tokenIDs[i]] = false;
                    royalty[offer.tokenIDs[i]].bundledID = 0;
                    share2 = (offer.minValue * royalty[offer.tokenIDs[i]].royalty) / 100;
                    total += share2;
                    payable(royalty[offer.tokenIDs[i]].originator).transfer(share2);
                    ERC721Like(nftAsset).transferFrom(address(this), bid.bidder, offer.tokenIDs[i]);
                }
                payable(offer.seller).transfer(bid.value - share1 - total - share3);
                offerBundleBalances[tokenID][bid.bidder] = 0;
                delete bundleBade[tokenID][bid.bidder];
                delete bundleBids[tokenID];
            }    
            emit Bought(
                offer.seller,
                bid.bidder,
                tokenID,
                bid.value
            );
            emit DealTransaction(
                tokenID,
                offer.isDonated,
                offer.seller,
                offer.seller
            );   
        } else {
            for(i = 0; i < offer.tokenIDs.length; i++) {
                ERC721Like(nftAsset).transferFrom(address(this), offer.seller, offer.tokenIDs[i]);
            }
            emit AuctionPass(tokenID);        
        }
        delete nftBundledForSale[tokenID];
        delete bundleBids[tokenID];
    }
}