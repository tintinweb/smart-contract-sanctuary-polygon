//SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2022 BDE Technologies LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./Executor.sol";
import "./TermsOfService.sol";

/**
 * 06
 *
 * @notice By interacting with this smartcontract I understand and accept 
 * the Polygods Terms of Service, including the limitations on the resale described therein. 
 * The Polygods Terms of Service is located at https://www.polygods.com/termsofservice
 *
 */
contract Polygods is Executor, TermsOfService {

    string private _contractURI;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /** 
     * 
     */
    constructor(
        address vrfCoordinator, 
        string memory baseURI_, 
        string memory contractURI_,
        address banned) Executor(
            "Polygods", 
            "POLYGODS", 
            baseURI_, 
            vrfCoordinator, 
            banned) {
        
        _admin = msg.sender;
        _contractURI = contractURI_;
    }

    /** 
     *
     */
    function withdraw() public {
        require(assigned, "Polygods: mint phase unconcluded");
        uint256 valueInWei = uint256(pendingWithdrawals[msg.sender]);

        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        _transfer(msg.sender, valueInWei);
    }

    /**
     *
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) external onlyAdmin {
        _contractURI = contractURI_;
    }

    function setAdmin(address admin_) external onlyAdmin {
        address adminPrior = _admin;
        _admin = admin_;
        emit OwnershipTransferred(adminPrior, admin_);
    }

    function adminWithdraw(address recipient, uint256 valueInWei) external onlyAdmin {
        _transfer(recipient, valueInWei);
    }

    function adminWithdraw20(address tokenContract, address recipient, uint256 amount) external onlyAdmin {
        (bool success, bytes memory data) = address(tokenContract).call(abi.encodeWithSelector(0xa9059cbb, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function adminWithdraw721(address tokenContract, address recipient, uint256 tokenId) external onlyAdmin {
        ERC721(tokenContract).safeTransferFrom(address(this), recipient, tokenId);
    }

}

//SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2022 BDE Technologies LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./Bidder.sol";

/**
 * 05
 *
 * @notice By interacting with this smartcontract I understand and accept 
 * the Polygods Terms of Service, including the limitations on the resale described therein. 
 * The Polygods Terms of Service is located at https://www.polygods.com/termsofservice
 *
 */
contract Executor is Bidder {

    event Bought(uint256 indexed tokenId, int256 value, address indexed from, address indexed to);

    constructor(
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_, 
        address vrfCoordinator,
        address banned) Bidder(
            name_, 
            symbol_, 
            baseURI_, 
            vrfCoordinator,
            banned) { 
    }

    /**
     * ...
     */
    function purchase(uint256 tokenId) public payable {
        require(assigned, "Polygods: mint phase unconcluded");
        require(_exists(tokenId), "Polygods: operator query for nonexistent token");

        Ask memory ask = activeListing[tokenId];
        require(ask.hasAsk, "Polygods: not for sale");
        
        int256 valueInWei = int256(msg.value);
        require(valueInWei >= ask.valueInWei, "Polygods: didn't send enough MATIC");
        
        address seller = ask.seller;
        require(seller == _owners[tokenId], "Polygods: seller is not owner"); 
        
        address to = msg.sender;
        
        _owners[tokenId] = to;
        _balances[seller]--;
        _balances[to]++;
        emit Transfer(seller, to, tokenId);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = _bids[tokenId];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.valueInWei;
            _bids[tokenId] = Bid(false, tokenId, address(0), 0);
        }

        emit Bought(tokenId, valueInWei, seller, to);

        Heap.Node memory floor = _getFloor();
        int256 baselinePrice = baseline[tokenId];

        if(valueInWei <= floor.priority || valueInWei < baselinePrice){
            _enforcePaperHandsNgmiTax(seller, valueInWei);
        } else {
            _createPendingWithdrawl(seller, valueInWei);
        }
        baseline[tokenId] = valueInWei;

        _extractById(tokenId);
        _noLongerForSale(tokenId);
        volumeTraded += msg.value;
    }

    /**
     *
     */
    function acceptBid(uint256 tokenId, int256 minValueInWei) public {
        require(assigned, "Polygods: mint phase unconcluded"); 
        require(_exists(tokenId), "Polygods: operator query for nonexistent token");

        Bid memory bid = _bids[tokenId];
        int256 bidValueInWei = bid.valueInWei;
        require(bidValueInWei != 0, "Polygods: invalid bid");
        require(bidValueInWei >= minValueInWei, "Polygods: value of bid less than min");

        address accepter = msg.sender;
        require(accepter == _owners[tokenId], "Polygods: accepter is not owner"); 

        address bidder = bid.bidder;
        
        _owners[tokenId] = bidder;
        _balances[accepter]--;
        _balances[bidder]++;
        emit Transfer(accepter, bidder, tokenId);
        
        _bids[tokenId] = Bid(false, tokenId, address(0), 0);
        
        emit Bought(tokenId, bidValueInWei, accepter, bidder);

        Heap.Node memory floor = _getFloor();
        int256 baselinePrice = baseline[tokenId];

        if(bidValueInWei <= floor.priority || bidValueInWei < baselinePrice){
            _enforcePaperHandsNgmiTax(accepter, bidValueInWei);
        } else {
            _createPendingWithdrawl(accepter, bidValueInWei);
        }
        baseline[tokenId] = bidValueInWei;

        Ask memory ask = activeListing[tokenId];
        if(ask.hasAsk){
            _noLongerForSale(tokenId);
            _extractById(tokenId);
        }
        volumeTraded += uint256(bidValueInWei);
    }

    /**
     * Credit us the royalty fee, give the rest to the seller
     */
    function _createPendingWithdrawl(address seller, int256 valueInWei) internal {
        int256 royaltyFee = (valueInWei * _percentageRoyalty) / _percentageTotal;
        int256 sellerProceeds = valueInWei - royaltyFee;

        pendingWithdrawals[_admin] += royaltyFee;
        pendingWithdrawals[seller] += sellerProceeds;
    }

}

//SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2022 BDE Technologies LLC. All Rights Reserved
pragma solidity ^0.8.x;

/**
 *
 * Polygods Terms of Service and Licensing Agreement
 * This Polygods Terms of Service and NFT License Agreement (this “Agreement”) is a legally binding agreement by and between BDE Technologies LLC (“BDE Technologies,” “us,” “we,” or “our”), a Delaware limited liability company, and any user of our services, including but not limited to users of the website www.polygods.com (“Polygods website”), owner of any Polygods NFT (defined below) (“Purchaser”) or any other individual or entity that uses the Art (defined below) without owning the associated Polygods NFT (defined below) (“Non-Commercial User”) (Purchasers and Non-Commercial Users, collectively, “Users” or “you”). BDE Technologies and each User may be referred to throughout this Agreement collectively as the “Parties” or individually as a “Party”. 
 * PLEASE READ THIS AGREEMENT CAREFULLY AS IT CONTAINS IMPORTANT INFORMATION AND AFFECTS YOUR LEGAL RIGHTS. AS OUTLINED IN SECTION 15 BELOW, IT INCLUDES A MANDATORY ARBITRATION AGREEMENT AND CLASS ACTION WAIVER WHICH (WITH LIMITED EXCEPTIONS) REQUIRES ANY DISPUTES BETWEEN USERS AND BDE TECHNOLOGIES TO BE RESOLVED THROUGH INDIVIDUAL ARBITRATION RATHER THAN BY A JUDGE OR JURY IN COURT. HOWEVER, IF YOU ARE A RESIDENT OF A JURISDICTION WHERE APPLICABLE LAW PROHIBITS ARBITRATION OF DISPUTES, THE AGREEMENT TO ARBITRATE IN SECTION 15 WILL NOT APPLY TO YOU, BUT THE PROVISIONS OF SECTION 14 (GOVERNING LAW AND FORUM CHOICE) OR RELEVANT PROVISIONS OF APPLICABLE LAW WILL STILL APPLY.
 * BY CLICKING TO ACCEPT AND/OR USING OUR SERVICE, INCLUDING BUT NOT LIMITED TO BUYING OR OWNING A POLYGODS NFT OR USING THE ART, YOU AGREE TO BE BOUND BY THIS AGREEMENT AND ALL OF THE TERMS INCORPORATED HEREIN BY REFERENCE. IF YOU DO NOT AGREE TO THESE TERMS, YOU MAY NOT ACCESS OR USE THE SERVICE OR ACQUIRE A POLYGODS NFT.
 * IMPORTANT NOTICE REGARDING A LIMITED ABILITY TO SELL/TRANSFER YOUR POLYGODS NFT: YOU UNDERSTAND AND SPECIFICALLY AGREE TO THE FOLLOWING BEFORE MINTING OR ACQUIRING A POLYGODS NFT. IF YOU DO NOT AGREE, YOU MUST NOT ACCESS OR USE THE SITE AND YOU MUST NOT ACQUIRE A POLYGODS NFT. 
 * 	•	NO SALE/TRANSFER BEFORE MINTED OUT: YOU ARE NOT ABLE TO SELL OR TRANSFER THE POLYGODS NFT YOU ACQUIRE BEFORE ALL 10,001 POLYGODS NFTS ARE SOLD (“MINTED OUT”). IT IS POSSIBLE THAT THIS MAY NEVER HAPPEN. BDE TECHNOLOGIES IS UNDER NO OBLIGATION TO ENSURE THAT THE POLYGODS NFTS WILL BE MINTED OUT.
 * 	•	AFTER MINTED OUT SALE/TRANSFER ONLY VIA OUR MARKETPLACE: IF AND WHEN THE POLYGODS NFTS ARE MINTED OUT, YOU ARE ONLY ABLE TO SELL OR TRANSFER THE POLYGODS NFT ON OUR MARKETPLACE OR DIRECTLY VIA THE SMART CONTRACT (E.G., THROUGH ETHERSCAN). CURRENTLY, MARKETPLACES SUCH AS OPENSEA OR LOOKSRARE DO NOT SUPPORT THE POLYGODS SMART CONTRACT. THIS MEANS THAT YOU CANNOT OFFER, LIST, OR SELL YOUR POLYGODS NFT OVER ANY THIRD-PARTY MARKETPLACE. IN ORDER TO BE ABLE TO OFFER, LIST OR SELL YOUR POLYGODS NFT ON A THIRD-PARTY MARKETPLACE, THE MARKETPLACE MUST INTEGRATE OUR SMART CONTRACT. WE DO NOT KNOW IF, AND, IF SO, WHEN THIS WILL HAPPEN AND DO NOT MAKE ANY REPRESENTATIONS HEREOVER.
 * 	•	“PAPERHAND NGMI TAX” – 35% Chance that you will not receive THE NET sale proceeds (the sale proceeds MINUS 10% TRANSFER ROYALTY fee owed to us – “Net Sale Proceeds”) if you sell your Polygods NFT at or lower than floor price or for less than what you bought it for:
 * 	•	if you sell your Polygods NFT at the floor price (the lowest price a Polygods NFT is currently listed for sale, the “Floor Price”), i.e., there is no other Polygods NFT listed at a lower price on the market, there is a 35% chance that the proceeds from the sale will be allocated by the smart contract to a blockchain wallet controlled by BDE Technologies and not to you, the seller; i.e., in this case you will not receive the proceeds of the sale. The randomness (35% probability) is determined in the smart contract via Chainlink VRF (https://docs.chain.link/docs/chainlink-vrf/) that is, at the time of this Agreement, industry best practice. 
 * 	•	if you accept a bid for your Polygods NFT that is equal to or lower than the Floor Price, there is a 35% chance that the proceeds from the sale will be allocated by the smart contract to a blockchain wallet controlled by BDE Technologies and not to you, the seller; i.e., in this case you will not receive the proceeds of the sale. The randomness (35% probability) is determined in the smart contract via Chainlink VRF (https://docs.chain.link/docs/chainlink-vrf/) that is, at the time of this Agreement, industry best practice.
 * 	•	if you sell your Polygods NFT for less than what you bought it for, there is a 35% chance that the proceeds from the sale will be allocated by the smart contract to a blockchain wallet controlled by BDE Technologies and not to you, the seller; i.e., in this case you will not receive the proceeds of the sale. The randomness (35% probability) is determined in the smart contract via Chainlink VRF (https://docs.chain.link/docs/chainlink-vrf/) that is, at the time of this Agreement, industry best practice.
 * 1. Polygods NFT Defined. “Polygods NFT” refers to a non-fungible, unique token on the Polygon blockchain (“NFT”) (i.e., a controllable electronic record on a blockchain) that, as of its genesis issuance, contains images of Art. “Art” means each of the unique images of Polygods characters, each associated with, and linked to, an individual Polygods NFT.
 * 2. Additional Terms. Polygods NFTs are currently not available for purchase on third-party platforms. We do not know if and if so when they will become available on these platforms, this would require the third-party platform to integrate our smart contract. If they become available for purchase on one or more third-party platforms, such as OpenSea, or other marketplaces that may be established from time to time (each, an “NFT Marketplace”), which we do not operate, or by direct purchase or transfer from unaffiliated owners of Polygods NFTs, the following will apply: The access and use of any NFT Marketplace is subject to the separate terms of that NFT Marketplace. In addition, although we do not guarantee that they will, third parties may grant Polygods NFT owners various entitlements and benefits. If a third party does so, such entitlements and benefits will be subject to whatever terms are provided by such third parties. We are not responsible or liable for any third-party NFT Marketplace or any third-party entitlements or benefits. Purchasers covenant not to sue BDE Technologies based on activities that may occur on such NFT Marketplaces, due to third-party benefits or entitlements, or in connection with any direct purchase or transfers with unaffiliated owners of Polygods NFTs in which Purchasers may engage.
 * 3. Ownership of a Polygods NFT.
 * (a) When a Purchaser acquires a Polygods NFT, that Purchaser owns all personal property rights to that Polygods NFT (e.g., subject to otherwise described herein smart contract functions, the right to sell, transfer, or otherwise dispose of that Polygods NFT). At no point may we seize, freeze, or otherwise modify the ownership of any Polygods NFT. Such rights, however, do not include the ownership of the intellectual property rights in the Art. Such rights are licensed pursuant to Section 4 below and those terms govern your use of the Art.
 * (b) Purchaser understands and agrees that Purchaser is not able to sell or transfer the Polygods NFT before all 10,001 Polygods NFT are sold (“minted out”) – it is possible that this may never happen. BDE Technologies is under no obligation to ensure that the Polygods NFT will be minted out. Purchaser further understands and agrees that if and when the Polygods are minted out, Purchaser is only able to sell or transfer the Polygods NFT on our marketplace (www.polygods.com) or directly via the smart contract. Currently, third-party NFT Marketplaces do not currently support the Polygods smart contract. Purchaser understands that this means that Purchaser is not able to offer, list or sell a Polygods NFT over any third-party NFT Marketplace. In order to be able to offer, list, or sell your Polygods NFT on a third-party NFT Marketplace, the third-party Marketplace must integrate our smart contract. We do not know if, and if so, when this will happen and do not make any representations hereover. Subject to this, Purchaser may sell or otherwise transfer their Polygods NFT consistent with Purchaser’s rights in it as defined in this Agreement (a “Permitted Transfer”), so long as the Transferee (as defined below) is not (i) located in a country that is subject to a U.S. Government embargo, or that has been designated by the U.S. Government as a terrorist-supporting country; or (ii) listed on any U.S. Government list of prohibited or restricted parties (a “Prohibited Transferee”). Purchaser represents and warrants that it is not and will not transfer a Polygods NFT to a Prohibited Transferee.
 * (c) Paperhand NGMI Tax – Purchaser understands and agrees that there is a 35% chance that you will not receive the net sale proceeds (sale proceeds minus a 10% transfer royalty fee owed to us – “Net Sale Proceeds”) if:
 * if you sell your Polygods NFT at the floor price (the lowest price a Polygods NFT is currently listed for sale, the “Floor Price”), i.e., there is no other Polygods NFT listed at a lower price on the market, there is a 35% chance that the proceeds from the sale will be allocated by the smart contract to a blockchain wallet controlled by BDE Technologies and not to you, the seller; i.e., in this case you will not receive the proceeds of the sale. The randomness (35% probability) is determined in the smart contract via Chainlink VRF (https://docs.chain.link/docs/chainlink-vrf/) that is, at the time of this Agreement, industry best practice. 
 * - if you accept a bid for your Polygods NFT that is equal to or lower than the Floor Price, there is a 35% chance that the proceeds from the sale will be allocated by the smart contract to a blockchain wallet controlled by BDE Technologies and not to you, the seller; i.e., in this case you will not receive the proceeds of the sale. The randomness (35% probability) is determined in the smart contract via Chainlink VRF (https://docs.chain.link/docs/chainlink-vrf/) that is, at the time of this Agreement, industry best practice.
 * - if you sell your Polygods NFT for less than what you bought it for, there is a 35% chance that the proceeds from the sale will be allocated by the smart contract to a blockchain wallet controlled by BDE Technologies and not to you, the seller; i.e., in this case you will not receive the proceeds of the sale. The randomness (35% probability) is determined in the smart contract via Chainlink VRF (https://docs.chain.link/docs/chainlink-vrf/) that is, at the time of this Agreement, industry best practice.
 * 4. License.
 * (a) Non-Commercial License to the Art for Users. Subject to your compliance with this Agreement, BDE Technologies hereby grants to you a non-exclusive, worldwide, royalty-free, revocable license, with the right to sublicense, to use, copy, distribute, create Derivative Works of (subject to the below) and display the Art linked to a Polygods NFT for your own personal, non-commercial use. This non-commercial license does not include the right to use that Art for any direct or indirect revenue generating purposes. For example, this license does not include the right to sell Derivative Works of the Art or use the Art in connection with the marketing or promotion of any product, service or business.
 * (b) Full Commercial License to the Art for Purchasers. In addition, subject to Purchaser’s compliance with this Agreement, BDE Technologies hereby grants to Purchaser, for so long as Purchaser owns a Polygods NFT (as recorded on the relevant blockchain), an exclusive (except as to BDE Technologies and its licensees), worldwide license, with the right to sublicense, to use, copy, distribute, create Derivative Works of (subject to the below), and display the Art linked to the Purchaser’s purchased Polygods NFT for Commercial Purposes. “Commercial Purposes” means the use of the Art for all lawful commercial purposes, whether known now or created in the future. Such purposes may include merchandising, inclusion in physical or digital media, or display in “metaverses” or other interactive digital environments.
 * (c) Derivative Works. Your rights include the right to create derivative works of the Art to depict the Polygods NFT character or any modification, adaptation or derivation thereof in goods or media by, for example, showing their full body or back, or reformatting the relevant Art for a particular medium (“Derivative Works”), except that you may not create Derivative Works of Art for one Polygods NFT that is confusingly similar to the Art for another Polygods NFT. Derivative Works are subject to the same limitations on the use of the underlying Art as set forth in Sections 4(a) and 4(b) of this Agreement, as applicable, i.e., you may only utilize Derivative Works for Commercial Purposes if you are the Purchaser of the applicable Polygods NFT. When you create Derivative Works, you hereby grant BDE Technologies a perpetual, irrevocable, fully sublicensable (through one or more tiers), worldwide, royalty-free license to use, copy, and display such Derivative Works in connection with BDE Technologies’ business.
 * (d) Transfer royalty fee. The above mentioned license is granted subject to a 10% transfer royalty fee (of the sale price) owed to BDE Technologies at the time of each sale. The smart contract will transfer 10% of the proceeds to BDE Technologies. 
 * (e) Enforcement. Subject to applicable law, you will have the sole and exclusive right, but not the obligation, to bring an action to enforce any infringement of any rights you hold in the Art linked to a Polygods NFT as set forth in Sections 4(a)-(c). We will have no obligation to support any such action.
 * (f) Protection for Purchasers. Subject to applicable law, Purchaser will have the right to procure registration or other intellectual property protection in the Art linked to Purchaser’s Polygods NFT. However, Purchaser must and hereby do agree to transfer any such registration or other protection in connection with a permitted transfer or sale of Purchaser’s Polygods NFT.
 * (g) Name and Trademarks. As provided in Section 5(c), no trademark rights are granted to Purchaser by BDE Technologies, except the limited right to use the name of any character, location or item represented in the Art associated with a Purchaser’s Polygods NFT in connection with a Purchaser’s exercise of rights under Sections 4(a) or 4(b). However, Purchaser may acquire trademark rights itself in Purchaser’s Polygods NFT (which, for avoidance of doubt, do not include rights to the “Polygods” trademark) through the exercise of Purchaser’s license rights above in accordance with, and subject to, applicable law. Any trademark rights that Purchaser acquires, and the associated goodwill, will transfer in connection with a Permitted Transfer of Purchaser’s Polygods NFT.
 * (h) Transfer. The licenses in Section 4 are non-transferrable, except that they will automatically transfer in connection with a Permitted Transfer of Purchaser’s Polygods NFT.
 * 5. Reservation of Rights.
 * (a) General. All rights in and to the Art not expressly provided for in this Agreement are hereby reserved by BDE Technologies. The Art is licensed, not sold. BDE Technologies owns and will retain all title, interest, ownership rights and intellectual property rights in and to the Art.
 * (b) Limitations. Without limitation of Section 5(a) above, the license in Section 4(b) does not include the right to use the Art or any Derivative Works in any manner or for any purpose that promotes violence against or directly attacks or threatens or harasses other people, including on the basis of race, ethnicity, national origin, caste, sexual orientation, gender, gender identity, religious affiliation, age, disability, or serious disease (“Prohibited Uses”). If you engage in a Prohibited Use of Art or Derivative Works, BDE Technologies reserves the right to immediately terminate any licenses granted to you in this Agreement.
 * (c) No Rights to Trademarks. For avoidance of doubt, the licenses in Section 4 do not include the right to use any BDE Technologies’ trademarks (e.g., Polygods and BDE Technologies). No trademark or other rights based on designation of source or origin are licensed to you. Notwithstanding the foregoing, to the extent you acquire any rights to any Polygods trademarks, you hereby assign all rights, title, and interest in and to such trademarks, together with all associated goodwill. You may not use or attempt to register any asset, including any domain names, social media accounts, or related addresses that contains or incorporates any artwork, other representation, name, or mark that may be confusingly similar to such trademarks.
 * (d) Disputes Among Owners. BDE Technologies has no obligation to support the resolution of or to resolve any dispute that may arise between or among Polygods NFT owners.
 * (e) Clarifications. BDE Technologies reserves the right, but has no obligation, to clarify the terms of this Agreement in relation to novel or unforeseen circumstances in its sole and exclusive discretion.
 * 6. Transfers. Purchaser hereby agrees that all subsequent transactions involving Purchaser’s Polygods NFT are subject to the following terms: the Polygods NFT transferee (the “Transferee”) shall, by purchasing, accepting, accessing or otherwise using the Polygods website, marketplace, NFT or Art, be deemed to accept all of the terms of this Agreement as a “Purchaser” hereof; and (b) the Polygods NFT transferor (the “Transferor”) shall provide notice to the Transferee of this Agreement, including a link or other method by which the terms of this Agreement can be accessed by the Transferee. Purchaser further acknowledges and agrees that all subsequent transactions involving Purchaser’s Polygods NFT will be effected on the blockchain network governing the Polygods NFT, and Purchaser will be required to make or receive payments exclusively through its cryptocurrency wallet.
 * 7. BDE Technologies’ Rights and Obligations to the Art. BDE Technologies is not responsible for the ultimate rendering of the Art.
 * 8. Warranty Disclaimers and Assumption of Risk. User represents and warrants that it (a) is the age of majority in User’s place of residence and has the legal capacity to enter into this Agreement, (b) that User will use and interact with the Polygods website, marketplace, NFTs and Art, as applicable, only for lawful purposes and in accordance with this Agreement, and (c) that User will not use the Polygods website, marketplace, NFT or Art, as applicable, to violate any law, regulation or ordinance or any right of BDE Technologies, its licensors, or any third party, including without limitation, any right of privacy, publicity, copyright, trademark, or patent. User further represents and warrants that it will comply with all applicable law in the exercise of its rights and obligations under this Agreement.
 * THE POLYGODS NFTS AND ART ARE PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND. WITHOUT LIMITING THE FOREGOING, BDE TECHNOLOGIES EXPLICITLY DISCLAIMS ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT AND NON-INFRINGEMENT, AND ANY WARRANTIES ARISING OUT OF COURSE OF DEALING OR USAGE OF TRADE. BDE TECHNOLOGIES MAKES NO WARRANTY THAT THE POLYGODS NFTS OR ART WILL MEET PURCHASER’S REQUIREMENTS, BE CONTINUALLY DISPLAYED, OR BE AVAILABLE ON AN UNINTERRUPTED, SECURE, OR ERROR-FREE BASIS. BDE TECHNOLOGIES MAKES NO WARRANTY REGARDING THE QUALITY, ACCURACY, TIMELINESS, TRUTHFULNESS, COMPLETENESS, OR RELIABILITY OF ANY INFORMATION OR CONTENT MADE AVAILABLE WITH RESPECT TO THE POLYGODS NFTS OR ART.
 * BDE TECHNOLOGIES WILL NOT BE RESPONSIBLE OR LIABLE TO PURCHASER FOR ANY LOSS IN CONNECTION WITH ANY POLYGODS NFT OR ART AND TAKES NO RESPONSIBILITY FOR, AND WILL NOT BE LIABLE TO PURCHASER FOR, ANY USE OF THE POLYGODS NFTS OR ART, INCLUDING BUT NOT LIMITED TO ANY LOSSES, DAMAGES OR CLAIMS ARISING FROM: (I) USER ERROR SUCH AS FORGOTTEN PASSWORDS, INCORRECTLY CONSTRUCTED TRANSACTIONS, OR MISTYPED WALLET ADDRESSES; (II) THE BEHAVIOR OR OUTPUT OF ANY SOFTWARE, NODE SERVER ERROR OR FAILURE, OR DATA LOSS OR CORRUPTION; (III) ANY FEATURES, DEVELOPMENT, ERRORS, OR OTHER ISSUES WITH BLOCKCHAIN NETWORKS; (IV) UNAUTHORIZED ACCESS TO THE POLYGODS NFT; OR (V) ANY THIRD PARTY ACTIVITIES, INCLUDING WITHOUT LIMITATION, THE USE OF VIRUSES, PHISHING, BRUTEFORCING OR OTHER MEANS OF ATTACK.
 * BDE TECHNOLOGIES WILL NOT BE RESPONSIBLE OR LIABLE FOR ANY LOSS OF PROCEEDS IN CONNECTION WITH THE PAPERHAND NGMI TAX: YOU UNDERSTAND AND SPECIFICALLY AGREE TO THE SMART CONTRACT MECHANISM AND THE RESULTS OF THE PAPERHAND NGMI TAXI. IF YOU DO NOT AGREE, YOU MUST NOT ACCESS OR USE THE SITE AND YOU MUST NOT ACQUIRE A POLYGODS NFT.
 * THE POLYGODS NFTS ARE INTANGIBLE DIGITAL ASSETS. THEY EXIST ONLY BY VIRTUE OF THE OWNERSHIP RECORD MAINTAINED ON THE APPLICABLE BLOCKCHAIN NETWORK. ANY TRANSFER OF TITLE THAT MIGHT OCCUR IN ANY UNIQUE DIGITAL ASSET OCCURS ON THE DECENTRALIZED LEDGER WITHIN SUCH BLOCKCHAIN NETWORK, WHICH BDE TECHNOLOGIES DOES NOT CONTROL. BDE TECHNOLOGIES DOES NOT GUARANTEE THAT BDE TECHNOLOGIES CAN EFFECT THE TRANSFER OF TITLE OR RIGHT IN ANY POLYGODS NFT. PURCHASER BEARS FULL RESPONSIBILITY FOR VERIFYING THE IDENTITY, LEGITIMACY, AND AUTHENTICITY OF ASSETS. NOTWITHSTANDING INDICATORS AND MESSAGES THAT SUGGEST VERIFICATION, BDE TECHNOLOGIES MAKES NO CLAIMS ABOUT THE IDENTITY, LEGITIMACY, OR AUTHENTICITY OF ASSETS.
 * SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OF IMPLIED WARRANTIES IN CONTRACTS WITH CONSUMERS, SO THE ABOVE EXCLUSION MAY NOT APPLY TO YOU, AS APPLICABLE.
 * 9. Assumption of Risk. Purchaser accepts and acknowledges all risks associated with the following:
 * (a) Purchaser is solely responsible for determining what, if any, taxes apply to Purchaser’s purchase, sale, or transfer of rights in the Polygods NFTs or to any Purchaser Revenue or Opportunity Revenue. BDE Technologies is not responsible for determining or paying the taxes that apply to such transactions.
 * (b) BDE Technologies does not store, send, or receive cryptocurrency assets. Any transfer of cryptocurrency assets occurs within the supporting blockchain, possibly with support from an NFT Marketplace or other third-party services, all of which are not controlled by BDE Technologies. Transactions relating to Polygods NFTs may be irreversible, and, accordingly, losses due to fraudulent or accidental transactions may not be recoverable. Some transactions relating to the Polygods NFT shall be deemed to be made when recorded on a public blockchain ledger, which is not necessarily the date or time that Purchaser initiated the transaction.
 * (c) There are risks associated with using an Internet based digital asset, including but not limited to, the risk of hardware, software, and Internet connection and service issues, the risk of malicious software introduction, and the risk that third parties may obtain unauthorized access to information stored within your wallet. BDE Technologies will not be responsible for any communication failures, disruptions, errors, distortions, or delays Purchaser may experience when effecting transactions relating to Polygods NFTs, however caused.
 * (d) Polygods NFTs may rely on third-party or decentralized platforms or systems. We do not maintain, control, or assume any obligations with respect to such platforms or systems.
 * 10. Links to Third-Party Websites or Resources. Use and interaction of the Polygods NFTs and the Art, as applicable, may allow User to access third-party websites or other resources. To the extent that BDE Technologies provides links or access to such sites and/or resources, it does so only as a convenience and is not responsible for the content, products, or services on or available from those resources or through any links displayed on such websites. User acknowledges sole responsibility for, and assumes all risk arising from, User’s use of any third-party sites or resources. Under no circumstances shall User’s inability to view or use Art on a third-party website serve as grounds for a claim against BDE Technologies.
 * 11. Termination of License to the Art. User’s licenses to the Art shall automatically terminate and all rights shall revert to BDE Technologies if at any time: (a) User breaches any portion of this Agreement or (b) User engages in any unlawful activity related to the Polygods NFT (including transferring the Polygods NFT to a Prohibited Transferee), as applicable. Upon any termination, discontinuation or cancellation of User’s licenses to the Art, BDE Technologies may disable User’s access to the Art and User shall delete, remove, or otherwise destroy any back up or other digital or physical copy of the Art. Upon any termination, discontinuation, or cancellation of the license in this Agreement, the following Sections will survive: 3, 5 through 16.
 * 12. Indemnity. User shall defend, indemnify, and hold BDE Technologies, its licensors and affiliates, and each of them, and all of their respective officers, directors, employees and agents (the “Indemnified Parties”) harmless from and against any and all claims, damages, losses, costs, investigations, liabilities, judgments, fines, penalties, settlements, interest, and expenses (including attorneys’ fees) that directly or indirectly arise from or are related to any claim, suit, action, demand, or proceeding made or brought by a third party (including any person who accesses or transacts using the Polygods NFTs whether or not such person personally purchased the Polygods NFTs) against the Indemnified Parties, or on account of the investigation, defense, or settlement thereof, arising out of or in connection with, as applicable, (a) your access to or use of the NFT Marketplace or any third-party services or products, (b) your breach or alleged breach of this Agreement, or (c) your exercise of the licenses in Section 4.
 * 13. Limitation of Liability.
 * (a) TO THE MAXIMUM EXTENT PERMITTED BY LAW, NEITHER BDE TECHNOLOGIES, NOR ANY OF ITS SERVICE PROVIDERS INVOLVED IN CREATING, PRODUCING, OR DELIVERING THE POLYGODS NFTS, WILL BE LIABLE FOR ANY INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES, OR DAMAGES FOR LOST PROFITS, LOST REVENUES, LOST SAVINGS, LOST BUSINESS OPPORTUNITY, LOSS OF DATA OR GOODWILL, SERVICE INTERRUPTION, COMPUTER DAMAGE OR SYSTEM FAILURE, OR THE COST OF SUBSTITUTE SERVICES OF ANY KIND ARISING OUT OF OR IN CONNECTION WITH THIS AGREEMENT OR FROM THE USE OF OR INABILITY TO USE OR INTERACT WITH THE POLYGODS NFTS OR ACCESS THE ART, WHETHER BASED ON WARRANTY, CONTRACT, TORT (INCLUDING NEGLIGENCE), PRODUCT LIABILITY, OR ANY OTHER LEGAL THEORY, AND WHETHER OR NOT BDE TECHNOLOGIES OR ITS SERVICE PROVIDERS HAVE BEEN INFORMED OF THE POSSIBILITY OF SUCH DAMAGE, EVEN IF A LIMITED REMEDY SET FORTH HEREIN IS FOUND TO HAVE FAILED OF ITS ESSENTIAL PURPOSE.
 * (b) TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT WILL BDE TECHNOLOGIES’ TOTAL LIABILITY ARISING OUT OF OR IN CONNECTION WITH THIS AGREEMENT, OR THE USE OF OR INABILITY TO USE OR INTERACT WITH THE POLYGODS NFTS OR ACCESS THE ART, OR ANY OF THE RIGHTS AND LICENSES GRANTED HEREIN EXCEED ONE THOUSAND U.S. DOLLARS ($1,000).
 * (c) BY PURCHASING A POLYGODS NFT, PURCHASER ACKNOWLEDGES THAT THE EXCLUSIONS AND LIMITATIONS OF DAMAGES SET FORTH ABOVE ARE FUNDAMENTAL ELEMENTS OF THE BASIS OF THE BARGAIN BETWEEN BDE TECHNOLOGIES AND PURCHASER.
 * 14. Governing Law and Forum Choice. This Agreement and any action related thereto will be governed by the U.S. Federal Arbitration Act, federal arbitration law, and the laws of the State of Delaware, without regard to its conflict of laws provisions. Except as otherwise expressly set forth in Section 15 “Dispute Resolution,” the exclusive jurisdiction for all Disputes (defined below) will be the state and federal courts located in Dover, Delaware, and you and BDE Technologies each waive any objection to jurisdiction and venue in such courts.
 * 15. Dispute Resolution.
 * (a) Informal Dispute Resolution. The Parties must first attempt to resolve any dispute, claim, or controversy arising out of or relating to this Agreement or the breach, termination, enforcement, interpretation, or validity thereof, or the use of the Polygods NFTs (collectively, “Disputes”) informally. Accordingly, neither Party may start a formal arbitration proceeding for at least sixty (60) days after one party notifies the other party of a claim in writing. As part of this informal resolution process, User must deliver a written notice of any Dispute via first-class mail to BDE Technologies at: BDE Technologies LLC, 8 The Green, Suite #12905, Dover, DE 19901.
 * (b) Mandatory Arbitration of Disputes. The Parties agree that any Dispute will be resolved solely by binding, individual arbitration and not in a class, representative, or consolidated action or proceeding. The Parties agree that the U.S. Federal Arbitration Act governs the interpretation and enforcement of this Agreement, and that each Party is waiving the right to a trial by jury or to participate in a class action. This arbitration provision shall survive termination of this Agreement.
 * (c) Exceptions. As limited exception to Section 15(b) above: (i) the Parties may seek to resolve a Dispute in small claims court if it qualifies; and (ii) each Party retains the right to seek injunctive or other equitable relief from a court to prevent (or enjoin) the infringement or misappropriation of our intellectual property rights.
 * (d) Conducting Arbitration and Arbitration Rules. The arbitration will be conducted by the American Arbitration Association (“AAA”) under its Consumer Arbitration Rules (the “AAA Rules”) then in effect, except as modified by this Agreement. The AAA Rules are available at www.adr.org or by calling 1-800-778-7879. A Party who wishes to start arbitration must submit a written Demand for Arbitration to AAA and give notice to the other Party as specified in the AAA Rules. The AAA provides a form Demand for Arbitration at www.adr.org. Any arbitration hearings will take place in the county (or parish) where you live, with provision to be made for remote appearances to the maximum extent permitted by the AAA rules, unless we both agree to a different location. The Parties agree that the arbitrator shall have exclusive authority to decide all issues relating to the interpretation, applicability, enforceability and scope of this arbitration agreement.
 * (e) Arbitration Costs. Payment of all filing, administration and arbitrator fees will be governed by the AAA Rules, and BDE Technologies won’t seek to recover the administration and arbitrator fees BDE Technologies is responsible for paying, unless the arbitrator finds your Dispute is frivolous. If BDE Technologies prevails in arbitration, BDE Technologies will pay all of its attorneys’ fees and costs and won’t seek to recover them from you. If you prevail in arbitration you will be entitled to an award of attorneys’ fees and expenses to the extent provided under applicable law.
 * (f) Injunctive and Declaratory Relief. Except as provided in Section 15(c) above, the arbitrator shall determine all issues of liability on the merits of any claim asserted by either party and may award declaratory or injunctive relief only in favor of the individual party seeking relief and only to the extent necessary to provide relief warranted by that party’s individual claim. To the extent that you or BDE Technologies prevail on a claim and seek public injunctive relief (that is, injunctive relief that has the primary purpose and effect of prohibiting unlawful acts that threaten future injury to the public), the entitlement to and extent of such relief must be litigated in a civil court of competent jurisdiction and not in arbitration. The Parties agree that litigation of any issues of public injunctive relief shall be stayed pending the outcome of the merits of any individual claims in arbitration.
 * (g) Class Action Waiver. YOU AND BDE TECHNOLOGIES AGREE THAT EACH MAY BRING CLAIMS AGAINST THE OTHER ONLY IN YOUR OR ITS INDIVIDUAL CAPACITY, AND NOT AS A PLAINTIFF OR CLASS MEMBER IN ANY PURPORTED CLASS OR REPRESENTATIVE PROCEEDING. Further, if a Dispute is resolved through arbitration, the arbitrator may not consolidate another person’s claims with your claims, and may not otherwise preside over any form of a representative or class proceeding. If this specific provision is found to be unenforceable, then the entirety of this Dispute Resolution section shall be null and void.
 * (h) Severability. With the exception of any of the provisions in Section 15(g) of this Agreement (“Class Action Waiver”), if an arbitrator or court of competent jurisdiction decides that any part of this Agreement is invalid or unenforceable, the other parts of this Agreement will still apply.
 * 16. General Terms. This Agreement will transfer and be binding upon and will inure to the benefit of the Parties and their permitted successors and assigns, in particular any permitted Transferee. This Agreement constitutes the entire agreement, and supersedes any and all prior or contemporaneous representations, understandings and agreements, between the Parties with respect to the subject matter of this Agreement, all of which are hereby merged into this Agreement. Without limitation, the terms of any other document, course of dealing, or course of trade will not modify this Agreement, except as expressly provided in this Agreement or as the Parties may agree in writing. This Agreement may be amended by BDE Technologies in its absolute and sole discretion; provided, that BDE Technologies shall give notice of any material amendments to this Agreement to the holders of the Polygods NFTs through reasonable and public means (i.e., public post on a social media network, e.g., Twitter) and BDE Technologies may not amend this Agreement to materially reduce or terminate any rights under Section 4(b). Failure to promptly enforce a provision of this Agreement will not be construed as a waiver of such provision. Nothing contained in this Agreement will be deemed to create, or be construed as creating, a joint venture or partnership between the parties. Neither Party is, by virtue of this Agreement or otherwise, authorized as an agent or legal representative of the other Party. Neither Party is granted any right or authority to assume or to create any obligation or responsibility, express or implied, on behalf or in the name of the other Party, or to bind such other Party in any manner. Nothing contained in this Agreement will be deemed to create any third-party beneficiary right upon any third party whatsoever. Each of the Parties acknowledges that it has had the opportunity to have this Agreement reviewed or not by independent legal counsel of its choice. If any one or more of the provisions of this Agreement should be ruled wholly or partly invalid or unenforceable, then the provisions held invalid or unenforceable will be deemed amended, and the arbitrator, court or other government body is authorized to reform the provision(s) to the minimum extent necessary to render them valid and enforceable in conformity with the Parties’ intent as manifested herein. The headings to Sections of this Agreement are for convenience or reference only and do not form a part of this Agreement and will not in any way affect its interpretation. Neither Party will be afforded or denied preference in the construction of this Agreement, whether by virtue of being the drafter or otherwise. For purposes of this Agreement, the words and phrases “include,” “includes,” “including” and “such as” are deemed to be followed by the words “without limitation”. Except as set forth in Section 15(a), User may give notice to BDE Technologies by contacting BDE Technologies at contact[at]polygods.com. Notice is effective upon receipt. The Parties have agreed to contract electronically, and accordingly, electronic signatures will be given the same effect and weight as originals.
 * 17. California Residents
 * If you are a California resident, in accordance with Cal. Civ. Code § 1789.3, you may report complaints to the Complaint Assistance Unit of the Division of Consumer Services of the California Department of Consumer Affairs by contacting them in writing at 1625 North Market Blvd., Suite N 112 Sacramento, CA 95834, or by telephone at (800) 952-5210.
 */

contract TermsOfService {}

//SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2022 BDE Technologies LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./VRF.sol";

/**
 * 04
 *
 * @notice By interacting with this smartcontract I understand and accept 
 * the Polygods Terms of Service, including the limitations on the resale described therein. 
 * The Polygods Terms of Service is located at https://www.polygods.com/termsofservice
 *
 */
contract Bidder is VRF {

    event BidEntered(uint256 indexed tokenId, int256 value, address indexed from);
    event BidWithdrawn(uint256 indexed tokenId, int256 value, address indexed from);

    mapping(uint256 => Bid) public _bids;

    constructor(
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_, 
        address vrfCoordinator,
        address banned) VRF(
            name_, 
            symbol_, 
            baseURI_, 
            vrfCoordinator,
            banned) { 
    }

    /**
     */
    function enterBid(uint256 tokenId) public payable {
        require(assigned, "Polygods: mint phase unconcluded");
        require(_exists(tokenId), "Polygods: query for nonexistent token");

        address bidder = msg.sender;
        require(_owners[tokenId] != bidder, "Polygods: you already own this nft");

        int256 valueInWei = int256(msg.value);
        require(valueInWei != 0, "Polygods: insufficient bid value");
        
        Bid memory existing = _bids[tokenId];
        require(valueInWei >= existing.valueInWei, "Polygods: insufficient bid value");
        
        if (existing.valueInWei > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.valueInWei;
        }
        _bids[tokenId] = Bid(true, tokenId, bidder, valueInWei);
        emit BidEntered(tokenId, valueInWei, bidder);
    }

    /**
     *
     */
    function withdrawBid(uint256 tokenId) public {
        require(assigned, "Polygods: mint phase unconcluded");            
        require(_exists(tokenId), "Polygods: query for nonexistent token");

        address bidder = msg.sender;
        require(_owners[tokenId] != bidder, "Polygods: you own this nft");
        
        Bid memory bid = _bids[tokenId];
        require(bid.bidder == bidder, "Polygods: not your bid");

        emit BidWithdrawn(tokenId, bid.valueInWei, bidder);

        _bids[tokenId] = Bid(false, tokenId, address(0), 0);

        uint256 valueInWei = uint256(bid.valueInWei);

        // Refund the bid money
        _transfer(bidder, valueInWei);  
    }

    /**
     *
     */
    function _transfer(address recipient, uint256 valueInWei) internal {
        (bool success,) = payable(recipient).call{value: valueInWei}("");
        require(success, "Polygods: value transfer unsuccessful");
    }

}

//SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2022 BDE Technologies LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./ListBurn.sol";
import "./vrf/VRFConsumerBaseV2.sol";
import "./vrf/VRFCoordinatorV2Interface.sol";

struct PendingWithdrawal {
    address seller;
    int256 valueInWei;
}

/**
 * 03A
 *
 * @notice By interacting with this smartcontract I understand and accept 
 * the Polygods Terms of Service, including the limitations on the resale described therein. 
 * The Polygods Terms of Service is located at https://www.polygods.com/termsofservice
 *
 */
contract VRF is VRFConsumerBaseV2, ListBurn {
    VRFCoordinatorV2Interface COORDINATOR;

    int256 immutable public _percentageTotal;
    int256 public _percentageRoyalty;

    mapping(address => int256) public pendingWithdrawals;

    event RandomResult(uint256 number);
    event RandomRequest(uint256 number);

    /// release the hold once we know the result of the random number, if applicable
    mapping(uint256 => PendingWithdrawal) private holdingWithdrawals;

    constructor(
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_, 
        address vrfCoordinator,
        address banned) VRFConsumerBaseV2(vrfCoordinator) ListBurn(
            name_, 
            symbol_, 
            baseURI_,
            banned)  {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

        _percentageTotal = 10000;
        _percentageRoyalty = 1000;
    }

    function setRoyaltyBips(int256 percentageRoyalty_) external onlyAdmin {
        require(percentageRoyalty_ <= _percentageTotal, "VRF: Illegal argument more than 100%");
        _percentageRoyalty = percentageRoyalty_;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        PendingWithdrawal memory pendingWithdrawal = holdingWithdrawals[requestId];
        address seller = pendingWithdrawal.seller;
        int256 valueInWei = pendingWithdrawal.valueInWei;

        // transform the result to a number between 1 and 100 inclusively
        uint256 result = (randomWords[0] % 100) + 1;
        if (result >= 35){
            // Credit us the royalty fee, give the rest to the seller
            int256 royaltyFee = (valueInWei * _percentageRoyalty) / _percentageTotal;
            int256 sellerProceeds = valueInWei - royaltyFee;

            pendingWithdrawals[_admin] += royaltyFee;
            pendingWithdrawals[seller] += sellerProceeds;
        } else {
            pendingWithdrawals[_admin] += valueInWei;
        }
        emit RandomResult(result);
    }

    function _enforcePaperHandsNgmiTax(address seller, int256 valueInWei) internal {
        //requestId - A unique identifier of the request. Can be used to match
        //a request to a response in fulfillRandomWords.
        uint64 s_subscriptionId = 97;
        uint32 numWords = 1;
        uint16 requestConfirmations = 200; //Maximum Confirmations

        bytes32 keyHash = 0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8; //polygon mainnet (1000 gwei)

        uint32 callbackGasLimit = 300000; 
        uint256 s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        holdingWithdrawals[s_requestId] = PendingWithdrawal(seller, valueInWei);
        emit RandomRequest(s_requestId);
    }    



}

//SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2022 BDE Technologies LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./MintInit.sol";
import "./DataStructure.sol";

/**
 * 02A
 *
 * @notice By interacting with this smartcontract I understand and accept 
 * the Polygods Terms of Service, including the limitations on the resale described therein. 
 * The Polygods Terms of Service is located at https://www.polygods.com/termsofservice
 *
 */
contract ListBurn is MintInit, DataStructure {

    event Offered(uint indexed tokenId, int256 minValue);
    event NoLongerForSale(uint256 indexed tokenId);

    mapping(uint256 => Ask) public activeListing;

    constructor(
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_,
        address banned) MintInit(
            name_, 
            symbol_, 
            baseURI_,
            banned) {
    }

    /**
     * @dev offer token for sale
     */
    function createListing(uint256 tokenId, int256 minSalePriceInWei) external {
        require(assigned, "Polygods: mint phase unconcluded");
        require(_exists(tokenId), "Polygods: nonexistent token");

        require(minSalePriceInWei > 0, "Polygods: price invalid");

        address seller = msg.sender;
        require(_owners[tokenId] == seller, "Polygods: not your polygod");

        _updateListing(tokenId, minSalePriceInWei, seller);
    }

    /**  
     *
     */
    function updateListing(uint256 tokenId, int256 minSalePriceInWei) external {
        require(assigned, "Polygods: mint phase unconcluded");
        require(_exists(tokenId), "Polygods: nonexistent token");

        require(minSalePriceInWei > 0, "Polygods: price invalid");

        address seller = msg.sender;
        require(_owners[tokenId] == seller, "Polygods: not your polygod");

        _updateListing(tokenId, minSalePriceInWei, seller);
    }

    /**  
     *
     */
    function _updateListing(uint256 tokenId, int256 minSalePriceInWei, address seller) private {
        _removeExistingNode(tokenId);
        _insert(minSalePriceInWei, tokenId);
        activeListing[tokenId] = Ask(true, tokenId, seller, minSalePriceInWei);
        emit Offered(tokenId, minSalePriceInWei);
    }
    
    /**  
     *
     */
    function _removeExistingNode(uint256 tokenId) private {
        // if it isn't there it'll return [0,0]
        Heap.Node memory node = _getById(tokenId);
        // it _isn't_ in there
        if(node.tokenId == 0){ 
            return;
        } // it is...
        _extractById(tokenId);
        _noLongerForSale(tokenId);
    }

    /**  
     *
     */
    function cancelListing(uint256 tokenId) external {
        require(assigned, "Polygods: mint phase unconcluded");
        require(_exists(tokenId), "Polygods: nonexistent token");

        require(_owners[tokenId] == msg.sender, "Polygods: not your polygod");

        _removeExistingNode(tokenId);
    }

    /**
     *
     */
    function burn(uint256 tokenId) public virtual {
        require(assigned, "Polygods: mint phase unconcluded");
        require(_exists(tokenId), "Polygods: nonexistent token");

        address owner = ownerOf(tokenId); 

        countBurn++;
        _balances[owner]--;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
        _removeExistingNode(tokenId);
    }

    /**
     *
     */
    function _noLongerForSale(uint256 tokenId) internal {
        activeListing[tokenId] = Ask(false, tokenId, msg.sender, 0);
        emit NoLongerForSale(tokenId);
    }

}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.x;

/**
 * 03B
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2022 BDE Technologies LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./Core.sol";

/**
 * 01
 *
 * @notice By interacting with this smartcontract I understand and accept 
 * the Polygods Terms of Service, including the limitations on the resale described therein. 
 * The Polygods Terms of Service is located at https://www.polygods.com/termsofservice
 *
 */
contract MintInit is Core {

    uint256 private countMax;
    uint256 private countMint;
    uint256 private countTotal;
    uint256 internal countBurn;
    
    uint256 public _mintPrice;
    uint256 public volumeTraded;

    mapping(uint256 => int256) public baseline; 

    bool internal active;
    bool internal assigned;
    bool internal initialized;

    event Assigned(bool assigned);

    address private frankdegods;

    constructor(
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_, 
        address banned) Core(name_, symbol_, baseURI_) {
        countMax = 20; 
        countMint = 1;

        countTotal = 10001;

        active = false;
        assigned = false;
        initialized = false;

        _mintPrice = 169000000000000000000;

        /* * */
        frankdegods = banned;
    }

    function initialize() external onlyAdmin {
        require(!initialized, "Polygods: operation invalid");
        /* * */
        uint256 reserve = 202;
        for(uint256 tokenId = 1; tokenId <= reserve; tokenId++) {
            _owners[tokenId] = _admin;
            emit Transfer(address(0), _admin, tokenId);
        }
        countMint += reserve;
        _balances[_admin] += reserve;
        /* * */
        active = true;
        initialized = true;
    }

   /**
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyAdmin {
        active = !active;
    }

    /**
     */
    function totalSupply() public view virtual returns (uint256) {
        return countMint - countBurn - 1;
    }

    /**
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        countMint++;
        if(totalSupply() == countTotal){
            assigned = true;
            emit Assigned(assigned);
        }

        volumeTraded += _mintPrice;

        baseline[tokenId] = int256(_mintPrice);

        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     *
     */
    function mint__I_UNDERSTAND_AND_ACCEPT_TERMS_OF_SERVICE(uint256 countCreate) external payable {
        require(!assigned, "Polygods: mint phase concluded");
        require(msg.sender != frankdegods, "Polygods: no Polygods for you!");
        require(active, "Polygods: sale inactive");
        require(countCreate > 0, "Polygods: invalid countCreate");
        require(countCreate <= countMax, "Polygods: exceeds mint txn limit - 0");

        require(totalSupply() + countCreate <= countTotal, "Polygods: exceeds token limit - 1");

        require(_mintPrice * countCreate <= msg.value, "Polygods: eth value insufficient");
        
        for(uint256 i = 0; i < countCreate; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (totalSupply() <= countTotal) {
                _mint(msg.sender, mintIndex);
            }
        } 
    }

    /* * */

    function updateBanned(address banned) public onlyAdmin {
        frankdegods = banned;
    }


}

//SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2022 BDE Technologies LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./heap/Heap.sol";

/**
 * 02B
 *
 * @notice By interacting with this smartcontract I understand and accept 
 * the Polygods Terms of Service, including the limitations on the resale described therein. 
 * The Polygods Terms of Service is located at https://www.polygods.com/termsofservice
 *
 */
contract DataStructure {
    using Heap for Heap.Data;
    Heap.Data internal data;

    constructor() {
        data.init();
    }

    function getFloor() external view returns(Heap.Node memory){
        return _getFloor();
    }

    function _getFloor() internal view returns(Heap.Node memory){
        Heap.Node memory node = data.getFloorNode();
        return node;
    }

    function _insert(int256 minSalePriceInWei, uint256 punkIndex) internal {
        data.insert(minSalePriceInWei, punkIndex);
    }

    function _getById(uint256 tokenId) internal view returns(Heap.Node memory){
        return data.getById(tokenId);
    }

    /**
     *
     */
    function _extractById(uint256 tokenId) internal returns(Heap.Node memory){
        return data.extractById(tokenId);
    }

    function _isFloor(uint256 tokenId) internal view returns(bool){
        return data.isFloor(tokenId);
    }

}

//SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2022 BDE Technologies LLC. All Rights Reserved
pragma solidity ^0.8.x;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

struct Ask {
    bool hasAsk;
    uint256 tokenId;
    address seller;
    int256 valueInWei;
}

struct Bid {
    bool hasBid;
    uint256 tokenId;
    address bidder;
    int256 valueInWei;
}

/**
 * 00
 *
 * @notice By interacting with this smartcontract I understand and accept 
 * the Polygods Terms of Service, including the limitations on the resale described therein. 
 * The Polygods Terms of Service is located at https://www.polygods.com/termsofservice
 *
 */
contract Core is ERC721, IERC165, IERC721Metadata {
    string private _name;
    string private _symbol;
    string private _baseURI;

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;

    address internal _admin;

    string internal constant UNSUPPORTED_OPERATION = "ERC721: unsupported operation";

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Polygods: invalid msg.sender");
        _;
    }
    
    /**
     */
    constructor(string memory name_, string memory symbol_, string memory baseURI_) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
    }

    /**
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * 
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI, _toString(tokenId)));
    }

    function setBaseURI(string memory baseURI_) external onlyAdmin {
        _baseURI = baseURI_;
    }

    /**
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return _owners[tokenId];
    }

    /**
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * Do we still need this even???
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
        if (to.code.length == 0) {
            return true;
        }
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        if (
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f    // ERC721Metadata
        ) {
            return true;
        }
        return false;
    }

    function safeTransferFrom(address /*_from*/, address /*_to*/, uint256 /*_tokenId*/, bytes calldata /*data*/) public virtual override {
        revert(UNSUPPORTED_OPERATION);
    }

    function safeTransferFrom(address /*_from*/, address /*_to*/, uint256 /*_tokenId*/) public virtual override {
        revert(UNSUPPORTED_OPERATION);
    }

    function transferFrom(address /*_from*/, address /*_to*/, uint256 /*_tokenId*/) public virtual override {
        revert(UNSUPPORTED_OPERATION);
    }

    function approve(address /*_approved*/, uint256 /*_tokenId*/) public virtual override {
        revert(UNSUPPORTED_OPERATION);
    }

    function setApprovalForAll(address /*_operator*/, bool /*_approved*/) public virtual override {
        revert(UNSUPPORTED_OPERATION);
    }

    function getApproved(uint256 /*_tokenId*/) public view virtual override returns (address) {
        revert(UNSUPPORTED_OPERATION);
    }

    function isApprovedForAll(address /*_owner*/, address /*_operator*/) public view virtual override returns (bool) {
        revert(UNSUPPORTED_OPERATION);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

//SPDX-License-Identifier: GPL-3.0-or-later
// Shoutout Zac Mitton! @VoltzRoad
pragma solidity 0.8.x;

library Heap {

  struct Data {
      Node[] nodes; // root is index 1; index 0 not used
      mapping(uint256 => uint256) indices; // unique id => node index
  }

  struct Node {
      uint256 tokenId;
      int256 priority;
  }

  uint constant ROOT_INDEX = 1;

  //call init before anything else
  function init(Data storage self) internal{
    self.nodes.push(Node(0,0));
  }

  function insert(Data storage self, int256 priority, uint256 tokenId) internal returns(Node memory) {
    require(!isNode(getById(self, tokenId)), "exists already");

    int256 minimize = priority * -1;

    Node memory n = Node(tokenId, minimize);
    
    self.nodes.push(n);
    _bubbleUp(self, n, self.nodes.length-1);

    return n;
  }

  function extractMax(Data storage self) internal returns(Node memory){
    return _extract(self, ROOT_INDEX);
  }

  function extractById(Data storage self, uint256 tokenId) internal returns(Node memory){
    return _extract(self, self.indices[tokenId]);
  }

  //view
  function dump(Data storage self) internal view returns(Node[] memory){
    //note: Empty set will return `[Node(0,0)]`. uninitialized will return `[]`.
    return self.nodes;
  }

  function getById(Data storage self, uint256 tokenId) internal view returns(Node memory){
    return getByIndex(self, self.indices[tokenId]);//test that all these return the emptyNode
  }

  function getByIndex(Data storage self, uint256 i) internal view returns(Node memory){
    return self.nodes.length > i ? self.nodes[i] : Node(0,0);
  }

  function getFloorNode(Data storage self) internal view returns(Node memory){
    Node memory node = getByIndex(self, ROOT_INDEX);
    int256 priority = node.priority;
    node.priority  = priority * -1;
    return node;
  }

  function isFloor(Data storage self, uint256 tokenId) internal view returns(bool){
    Node memory node00 = getByIndex(self, ROOT_INDEX);
    Node memory node01 = getByIndex(self, self.indices[tokenId]);
    return node00.tokenId == node01.tokenId;
  }

  function size(Data storage self) internal view returns(uint256){
    return self.nodes.length > 0 ? self.nodes.length-1 : 0;
  }
  
  function isNode(Node memory n) internal pure returns(bool){
    return n.tokenId > 0;
  }

  //private
  function _extract(Data storage self, uint256 i) private returns(Node memory){//√
    if(self.nodes.length <= i || i <= 0){
      return Node(0,0);
    }

    Node memory extractedNode = self.nodes[i];
    delete self.indices[extractedNode.tokenId];

    Node memory tailNode = self.nodes[self.nodes.length-1];
    self.nodes.pop();

    if(i < self.nodes.length){ // if extracted node was not tail
      _bubbleUp(self, tailNode, i);
      _bubbleDown(self, self.nodes[i], i); // then try bubbling down
    }
    return extractedNode;
  }

  function _bubbleUp(Data storage self, Node memory n, uint256 i) private{//√
    if(i == ROOT_INDEX || n.priority <= self.nodes[i/2].priority){
      _insert(self, n, i);
    } else {
      _insert(self, self.nodes[i/2], i);
      _bubbleUp(self, n, i/2);
    }
  }

  function _bubbleDown(Data storage self, Node memory n, uint256 i) private{//
    uint256 length = self.nodes.length;
    uint256 cIndex = i*2; // left child index

    if(length <= cIndex){
      _insert(self, n, i);
    } else {
      Node memory largestChild = self.nodes[cIndex];

      if(length > cIndex+1 && self.nodes[cIndex+1].priority > largestChild.priority ){
        largestChild = self.nodes[++cIndex];// TEST ++ gets executed first here
      }

      if(largestChild.priority <= n.priority){ //TEST: priority 0 is valid! negative ints work
        _insert(self, n, i);
      } else {
        _insert(self, largestChild, i);
        _bubbleDown(self, n, cIndex);
      }
    }
  }

  function _insert(Data storage self, Node memory n, uint256 i) private{//√
    self.nodes[i] = n;
    self.indices[n.tokenId] = i;
  }
}