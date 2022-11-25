// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Ownable.sol";
// import 'hardhat/console.sol';

// contract RaffleTest is VRFConsumerBaseV2, Ownable{
contract RaffleTest is Ownable{

    // VRFCoordinatorV2Interface COORDINATOR;
    // Your subscription ID.
    // uint64 s_subscriptionId;

    // address vrfCoordinator =  0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;     //Goerli
    // address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;         //mumbai
  
    // bytes32 s_keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;      //Goerli
    // bytes32 s_keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;     //mumbai

    // uint32 callbackGasLimit = 2500000;
    // The default is 3, but you can set this higher.
    // uint16 requestConfirmations = 3;
    // For this example, retrieve 1 random value in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    // uint32 numWords;

    // token contract interface
   IERC721 public token;
    // ownable contract
    Ownable ownable;
    address public deployer;
    // Raffle ID
    uint256 private RaffleID;
    // Round ID
    // uint private RoundNo;
    // uint256 public newRequestId;

    uint256 public nonce;   //for generating randomnumber
    // uint256 public sumOfNumber = 12; //for sumOfNumber
    // uint256 public currentElement = 0;
    
    // string[] awards = ["cat", "dog", "rabbit", "goat", "horse"];
    // uint256[] weights = [1,0,5,3,2];

    string invalidArgument = "Invalid argument.";
    string callerNotOwner =  "Caller is not the Owner.";
    string RI_notExist = "Raffle round doesn't exist";

    // // event RandomNumber(int256 randomNumberGenerated);
    // event RequestRandomness(uint256 indexed requestId);
    // event ReceivedRandomness(uint256 indexed requestId, address[] indexed result);
    // event ReceivedRandomness(uint256 indexed requestId, int256 );
    event RaffleAnnouced(uint RaffleID, uint roundID, address[] winners, bytes32[] prizes);

    enum RaffleStatus {NotInitialized, Initialized, Running, Completed}
    
    struct Raffle{
        address creator;
        uint256 totalRounds;
        uint256 totalWinners;
        uint256[2] startingRounds; // first index for the number of rounds and second for the winners of that round.
        uint256[2] endingRound;
        uint256 threshold;
        uint256 currentRound;
        // uint256 currentElement;
        bytes32[] prizes;
        address[] participants;
        uint256[] weights;
        RaffleStatus status;
        bool ignorePreviousWinner;
        // bool claimApplied;
        bool regRequired;
    }
    // raffle id => raffle data
    mapping(uint => Raffle) private raffle;

    // raffle id => participants addresses
    // mapping(uint => address[]) private participants;

    //for getting winners of the raffle Id
    // raffle id => round id => winners addresses
    mapping(uint => mapping(uint => address[])) private winnersOfTheRaffleID;  
    
    // mapping(uint => mapping(uint => bytes32[])) private awardsOfTheRaffleID;

    //for award of the winner
    //      raffleId   => round num     => address  => prize in bytes
    mapping(uint => mapping(uint => mapping(address => bytes32))) private winnersAward;

    //for claim track of the prizes of winner
    //Raffle Id     => round Id    => walletAddress => true
    mapping(uint => mapping(uint => mapping(address => bool))) private isClaimed;
    
    mapping(uint => mapping(address => bool)) public isRegistered;
    // raffle id => winner address => prize/award tag    
    // mapping(uint => mapping(address => bytes32)) public winnerPrize;

    // mapping(string => uint) public weightsOfPrizes;
    
    // prizes data, the use of this array is just for picking prizes from frontend
    // and then assign the prizzes when fulfillRandomWords function will call
    // bytes32[] private prizes;

   // mapping(uint => mapping(address => bool)) isParticipate;

//    mapping(uint256 => mapping(address => bool)) public isRegistered;

    modifier onlyOwner() override {
        if(address(ownable) != address(0)){
        require(
        ownable.verifyOwner(msg.sender) == true ||
        verifyOwner(msg.sender) == true,
        callerNotOwner
        );
        } 
        else{
        require(
        verifyOwner(msg.sender) == true,
        callerNotOwner );
        }
        _;
    }



    modifier onlyDeployer() {
        require(msg.sender == deployer, 
            "Caller in not deployer"
        );
        _;
    } 

    modifier checkRaffle(uint Raffle_id){
        require(raffle[Raffle_id].status == RaffleStatus.Initialized || raffle[Raffle_id].status == RaffleStatus.Running, "Raffle is not Intialized or Running");       
        require((raffle[Raffle_id].currentRound +1) <= raffle[Raffle_id].totalRounds, 
        RI_notExist);
        _;
    }

    // constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator){
    //     COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    //     s_subscriptionId = subscriptionId;
    //    // token = IERC721(_token);
    //     deployer= msg.sender;
    // }

    constructor(address _token){
        token = IERC721(_token);
        deployer= msg.sender;
    }

    /////////////////////////////////////////////////////////////////////////////////////////    
    //                                                                                     //
    //                                         START RAFFLE                                //
    //                                                                                     //
    /////////////////////////////////////////////////////////////////////////////////////////


    function startRaffle(
        uint256 Raffle_id, 
        uint256 totalRounds, 
        uint256 totalWinners, 
        uint256 threshold,
        bool ignorePreviousWinner,
        // bool claimApplied,
        bool regRequired
        ) external onlyOwner {
        require(threshold > 0, invalidArgument);
        require(raffle[Raffle_id].status == RaffleStatus.NotInitialized, "Raffle is already Initialized");
        require(totalWinners >= totalRounds,invalidArgument);
        
            
        // uint256[] memory prizes = abi.decode(_prizes, (bytes32[]));

        uint256 startingRoundsWinners = totalWinners / totalRounds;
        // console.log("startingRoundsWinners", startingRoundsWinners);
        uint256 lastRoundWinners = (totalWinners % totalRounds) + startingRoundsWinners;
        // console.log("lastRoundWinners", lastRoundWinners);

            uint256[2] memory starting;
            uint256[2] memory ending;

            starting[0] = totalRounds - 1;
            starting[1] = startingRoundsWinners;
            ending[0] = totalRounds;
            ending[1] = lastRoundWinners;

            address[] memory emptyAddressList;
            bytes32[] memory emptyPrizesList;
            uint256[] memory emptyWeightsList;

          raffle[Raffle_id] = Raffle(
            msg.sender,                 //creator
            totalRounds,                //totalRounds
            totalWinners,                //totalWinners
            starting,                    //startingRounds
            ending,                      //endingRound
            threshold,                   //threshold
            0,                           //currentRound
            // 0,                           //currentElement
            emptyPrizesList,             //prizes
            emptyAddressList,            //participants
            emptyWeightsList,            //weights
            RaffleStatus.Initialized,    //status
            ignorePreviousWinner,        //ignorePreviousWinner
            // claimApplied,                //claimApplied
            regRequired                  //regRequired
            );
    }

    function UserRegister(uint raffleID) checkRaffle(raffleID) external {
        require(token.balanceOf(msg.sender) > 0, "Not Enough NFT for registeration");
        require(raffle[raffleID].regRequired && !isRegistered[raffleID][msg.sender], invalidArgument);
        // require(!isRegistered[Raffle_id][msg.sender], "Wallet address is already Registered");
        // participants[Raffle_id].push(msg.sender);
        isRegistered[raffleID][msg.sender] = true;
        raffle[raffleID].participants.push(msg.sender);
    }

    /////////////////////////////////////////////////////////////////////////////////////////    
    //                                                                                     //
    //                                      SETTER FUNCTION                                //
    //                                                                                     //
    /////////////////////////////////////////////////////////////////////////////////////////
   
    function setPrizesAndWeights(uint Raffle_id, bytes memory _prizes, bytes memory _weights, uint256 sumOfSeats) external onlyOwner checkRaffle(Raffle_id) {
  
        require(sumOfSeats >= getRaffle(Raffle_id).totalWinners, "wrong amount of parameters.");

      
        bytes32[] memory prizes = abi.decode(_prizes, (bytes32[]));
        uint256[] memory weights = abi.decode(_weights, (uint256[]));

        
        raffle[Raffle_id].prizes = prizes;
        raffle[Raffle_id].weights = weights;
        
    }

    function setParticipants(uint Raffle_id, bytes memory _participants) external onlyOwner checkRaffle(Raffle_id){
        address[] memory participants = abi.decode(_participants, (address[]));
        raffle[Raffle_id].participants = participants;
    }

    
    function setOwnable(address ownableAddr) external onlyDeployer {
        require(ownableAddr != address(0) && ownableAddr != address(this), "Invalid ownable address.");
        ownable = Ownable(ownableAddr);
    }
    // function UserRegister(uint Raffle_id) external {
    //     require(raffle[Raffle_id].regRequired, "User Registration not required");
    //     require(isParticipate[Raffle_id][msg.sender] == false, "Wallet address is already Registered");
    //     participants[Raffle_id].push(msg.sender);
    // }

  
    // function random() public returns (uint, uint) {

    // uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 900;
    // // randomnumber = randomnumber + 100;
    // uint nextRandomNumber = randomnumber + 100;
    // nonce++;
    // return (randomnumber, nextRandomNumber);
    // }

    

  
    /////////////////////////////////////////////////////////////////////////////////////////    
    //                                                                                     //
    //                          PICK PARTICIPANTS AND AWARDS                               //
    //                                                                                     //
    /////////////////////////////////////////////////////////////////////////////////////////
    
    // function pickWinners(uint Raffle_id ) external onlyOwner checkRaffle(Raffle_id) returns (uint256 requestId) {

    //     if(getRaffle(Raffle_id).currentRound < getRaffle(Raffle_id).totalRounds){
    //     raffle[Raffle_id].currentRound++ ;
    //     raffle[Raffle_id].status =  RaffleStatus.Running;   
    //     }else {
    //         revert(RI_notExist);
    //     }
        
    //     uint256 winnersOfThisRound = getQtyOfWinners(Raffle_id, raffle[Raffle_id].currentRound);        

    //     RaffleID = Raffle_id;
    //     // RoundNo = raffle[Raffle_id].currentRound;
   
    //     numWords = uint32(winnersOfThisRound);
    //     // Will revert if subscription is not set and funded.
    //     requestId = COORDINATOR.requestRandomWords(
    //         s_keyHash,
    //         s_subscriptionId,
    //         requestConfirmations,
    //         callbackGasLimit,
    //         numWords
    //     );
    //     emit RequestRandomness(requestId);
    // }

    function pickAwards(uint256 raffleID, uint256 roundNum) external onlyOwner checkRaffle(raffleID) returns(bool){

        require(roundNum == (raffle[raffleID].currentRound + 1), "Wrong round number.");
        uint256 totalAwards = getQtyOfWinners(raffleID, roundNum);
        bool regRequired = getRaffle(raffleID).regRequired;

        address[] memory winners = getWinners(raffleID, roundNum);  //addresses of winners
        (bytes32[] memory prizes,) = getPrizesAndWeights(raffleID); //array of prizes
        
        bytes32[] memory awards = new bytes32[](totalAwards);   //array to be filled with awards index

        for(uint256 i = 0; i < totalAwards; i++){ 
            uint randomAward = randomAccordingToWeight(raffleID, roundNum);
            awards[i] = prizes[randomAward];
            // awardsOfTheRaffleID[raffleID][roundNum].push(prizes[i]);

            if(regRequired == false){
                winnersAward[raffleID][roundNum][winners[i]] = prizes[i];   //claiming
                isClaimed[raffleID][roundNum][winners[i]] = true;                  //claiming done
            }
        }       

        if(getRaffle(raffleID).currentRound < getRaffle(raffleID).totalRounds){
        raffle[raffleID].currentRound++ ;
        raffle[raffleID].status =  RaffleStatus.Running;   
        }else if(raffle[raffleID].totalRounds == roundNum){
            raffle[raffleID].status = RaffleStatus.Completed;
        }else {
            revert(RI_notExist);
        }

    

        emit RaffleAnnouced(raffleID, roundNum, getWinners(raffleID, roundNum), awards);


        return true;

    }

    function pickWinners(uint256 raffleID, uint256 roundNum) public onlyOwner checkRaffle(raffleID){
        require(roundNum == raffle[raffleID].currentRound + 1, "Wrong round number.");

        require(getWinners(raffleID, roundNum).length == 0, "Winners already announced.");
        //will pick winners according to the round qty of the raffle id
        randomWinners(raffleID, roundNum);     

    }
    
    
    function randomWinners(uint256 raffleID, uint256 roundNum) internal{
        
        uint256 r_number = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce)));
        // nonce++;

        uint256 totalWinners = getQtyOfWinners(raffleID, roundNum);

        address[] memory  participants = getParticipants(raffleID);

        // address[getParticipants(raffleID).length] memory participantsOfRaffle = getParticipants(raffleID);

        for(uint i = 0; i < totalWinners; i++){
            // uint256 randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce)));
            uint256 winnerIndex = (r_number % (participants.length - 1)) + 1;

            address winner = participants[winnerIndex];
       
            winnersOfTheRaffleID[raffleID][roundNum].push(winner);
            nonce++;
            r_number -= (i + 2);
            // console.log("r_number", r_number);
            // console.log("r_number -", ((r_number % (participants.length-1)) + 1));

            participants[winnerIndex] = participants[participants.length - 1];  // winner index moved to last index
            participants = participantsPop(participants);
        }

            if(raffle[raffleID].ignorePreviousWinner == true){
                raffle[raffleID].participants = participants;
            }
    }

    function participantsPop(address[] memory participants) internal pure returns(address[] memory){

        address[] memory newParticipants = new address[](participants.length -1);

        for(uint i = 0; i < participants.length - 1; i++){
                newParticipants[i] = participants[i];
        }

        return newParticipants;
    }

    function awardsPop(bytes32[] memory awards) internal pure returns(bytes32[] memory){

        bytes32[] memory newAwards = new bytes32[](awards.length -1);

        for(uint i = 0; i < awards.length - 1; i++){
                newAwards[i] = awards[i];
        }

        return newAwards;
    }

    function weightsPop(uint256[] memory weights) internal pure returns(uint256[] memory){

        uint256[] memory newWeights = new uint256[](weights.length -1);

        for(uint i = 0; i < weights.length - 1; i++){
                newWeights[i] = weights[i];
        }

        return newWeights;
    }
    

    // function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    //     address[] memory _participants = getParticipants(RaffleID);
    //     uint256 RoundNo = getRaffle(RaffleID).currentRound;

    //     for(uint256 i=0; i<randomWords.length; i++){
    //         address winner = _participants[(randomWords[i] % _participants.length) + 1];
    //         winnersOfTheRaffleID[RaffleID][RoundNo].push(winner);
    //         // winnerPrize[RaffleID][winner] = prizes[i];
    //     }
    //     if(raffle[RaffleID].totalRounds == RoundNo){
    //         raffle[RaffleID].status = RaffleStatus.Completed;
    //     }
    //     // prizes = new bytes32[](0);
    //     RaffleID = 0;
    //     RoundNo = 0;

    //     emit ReceivedRandomness(requestId, winnersOfTheRaffleID[RaffleID][RoundNo]);
    // }

    //   function randomAccordingToWeight(uint256 raffleID) internal returns(uint){
    //     uint256 randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce)));
    //     console.log("randomnumber", randomnumber);

    //     nonce ++;

    //     uint256 totalRuns = 0;      //Total count of the for loop
    //     uint256 totalIteration;     //Total number of iteration within the loop
    //     uint256 storedVariable;     //to be used for the next loop
    //     uint i;
    //     bool randomNumberFound; 

    //     (bytes32[] memory awards, uint256[] memory weights) = getPrizesAndWeights(raffleID);
    //     // uint256[] memory weights = getPrizesAndWeights(raffleID)[1];
    //     uint256 currentElement = raffle[raffleID].currentElement;
        

    //     if(currentElement == 0){    // if the currentElement is 0
    //             totalRuns = 1;      //then totalRuns will be 1
    //             totalIteration = awards.length;    //Total iteration for the loop will be complete according to length
    //             // console.log("totalIteration in if", totalIteration);
    //     } else if (currentElement != 0 ){     // if the current Element is not Zero and less than the total length
    //             totalRuns = 2;      
    //             // console.log("totalRuns in else", totalIteration);
    //     }

    //     while(totalRuns > 0 && !randomNumberFound){
           
    //             if(currentElement != 0  && totalRuns == 2 ){
    //                 totalIteration = awards.length - (currentElement - 1); // 5-0 or 5-2
    //                 storedVariable = currentElement - 1;
    //                 // console.log("currentElement in nested if", currentElement);
    //                 // console.log("totalIteration in nested if", totalIteration);
    //             }  else if(currentElement != 0 && totalRuns == 1) {      //currentElement should  not be equal to zero
    //                 totalIteration = storedVariable; // 2
    //                 // console.log("currentElement in nested else", currentElement);
    //                 // console.log("totalIteration in nested else", totalIteration);
    //             }
            
    //         // console.log("totalRuns", totalRuns);
    //         // currentElement +=1;
    //         // console.log("currentElement", currentElement);
            
    //     for(i = currentElement; i < totalIteration; i++){
    //         require(currentElement < awards.length);
    //     if(weights[i] > 0){     //checking if the weight is greater than 0
    //         // console.log("weights[i]",weights[i]);
    //         randomnumber = (randomnumber % weights[i]) + 1;   
    //         weights[i] -= 1;
    //         if(currentElement < awards.length){
    //             currentElement = i + 1;
    //         }   else if(currentElement >= awards.length){
    //             currentElement = 0;
    //         }
    //         // console.log("currentElement", currentElement);
    //         randomNumberFound = true;
    //         break; 
    //     }
    //     }
    //     totalRuns--;
    //     }
    //         raffle[raffleID].currentElement = currentElement;
    //         raffle[raffleID].weights = weights;
    //         return randomnumber;

    // }

   
    
    function randomAccordingToWeight(uint256 raffleID, uint256 roundNum) internal returns(uint256){
        

        uint randomnumber;
        uint256 r_number = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce)));

        // address[] memory _participants = getParticipants(RaffleID);
        // uint256 RoundNo = getRaffle(RaffleID).currentRound;

        uint256 totalAwards = getQtyOfWinners(raffleID, roundNum);
        (bytes32[] memory awards, uint256[] memory weights) = getPrizesAndWeights(raffleID);
        // uint256[] memory weights = getPrizesAndWeights(raffleID)[1];
        // uint256 currentElement = raffle[raffleID].currentElement;

        for(uint i = 0; i < totalAwards; i++){
   
            randomnumber = (r_number % (awards.length - 1)) + 1;   
            weights[i] -= 1;

            r_number -= (i + 2);

            if(weights[i] == 0){
                weights[i] = weights[weights.length-1];
                awards[i] = awards[awards.length - 1];

                awards = awardsPop(awards); 
                weights = weightsPop(weights);
              
            }
         }

            raffle[raffleID].prizes = awards;
            raffle[raffleID].weights = weights;
        

            return randomnumber;
    }

    function getClaimedStatusOfWinner(uint Raffle_id, uint Round_No, address wallet) external view returns(bool){
        require(winnersAward[Raffle_id][Round_No][wallet] != bytes32(0), "You are not a Winner");
        return isClaimed[Raffle_id][Round_No][wallet];
    }

    function claimAward(uint Raffle_id, uint Round_No) external{
        require(winnersAward[Raffle_id][Round_No][msg.sender] != bytes32(0), "You are not a Winner");
        require(!isClaimed[Raffle_id][Round_No][msg.sender], "You have already Claimed Award");
        isClaimed[Raffle_id][Round_No][msg.sender] = true;
    }
     

    /////////////////////////////////////////////////////////////////////////////////////////    
    //                                                                                     //
    //                                     GETTER FUNCTIONS                                //
    //                                                                                     //
    /////////////////////////////////////////////////////////////////////////////////////////

    function getQtyOfWinners(uint256 Raffle_id, uint256 roundNumber) public view returns(uint256 NumberOfWinners){
        
        require(raffle[Raffle_id].threshold > 0, RI_notExist);

        if(roundNumber <= getRaffle(Raffle_id).startingRounds[0]){
            return getRaffle(Raffle_id).startingRounds[1];
        } else if (roundNumber ==  getRaffle(Raffle_id).endingRound[0]){
            return getRaffle(Raffle_id).endingRound[1];
        }
    }

    function getRaffle(uint256 raffleID) public view returns(Raffle memory){
        return raffle[raffleID];
    }

    function seeAwardsOfTheWinner(uint256 raffleID, uint256 roundNum, address winner) public view returns(bytes32){
       return winnersAward[raffleID][roundNum][winner];
    }

    function getParticipants(uint Raffle_id) public view returns(address[] memory){
        // return participants[Raffle_id];
        return raffle[Raffle_id].participants;
    }


    function getPrizesAndWeights(uint Raffle_id) public view returns(bytes32[] memory, uint256[] memory){
        return (raffle[Raffle_id].prizes, raffle[Raffle_id].weights);
    }

    function getWinners(uint Raffle_id, uint Round_No) public view returns(address[] memory){
        return winnersOfTheRaffleID[Raffle_id][Round_No];
    }

    function getCurrentRound(uint Raffle_id) public view returns(uint){
        return getRaffle(Raffle_id).currentRound;
    }
    // function getAwards(uint Raffle_id, uint Round_No) public view returns(bytes32[] memory){
    //     return 
    // }

 

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// abstract contract Context {
   
// }

contract Ownable  {
    address private _owner;
    uint256 public totalOwners;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address[] private ownersArray;
    mapping(address => bool) private owners;

    constructor() {
        _transferOwnership(_msgSender());
        owners[_msgSender()] = true;
        totalOwners++;
    }

     function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    // It will return the address who deploy the contract
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlySuperOwner(){
        require(owner() == _msgSender(), "Ownable: caller is not the super owner");
        _;
    }

    modifier onlyOwner() virtual {
        require(owners[_msgSender()] == true, "Ownable: caller is not the owner");
        _;
    }

  
    function transferOwnership(address newOwner) public virtual onlySuperOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addOwner(address newOwner) public onlyOwner {
        require(owners[newOwner] == false, "This address have already owner rights.");
        owners[newOwner] = true;
        totalOwners++;
        ownersArray.push(newOwner);
    }

    function findOwnerAddress(address _ownerAddr) internal view returns(uint256 index){
        for(uint i = 0; i < ownersArray.length; i++){
            if(ownersArray[i] == _ownerAddr){
                index = i;
            }
        }
    }

    function removeOwner(address _Owner) public onlyOwner {
        require(owners[_Owner] == true, "This address have not any owner rights.");
        owners[_Owner] = false;
        totalOwners--;
        uint256 index = findOwnerAddress(_Owner);
        require(index >= 0, "Invalid index!");
        for (uint i = index; i<ownersArray.length-1; i++){
            ownersArray[i] = ownersArray[i+1];
        }
        ownersArray.pop();
    }

    function verifyOwner(address _ownerAddress) public view returns(bool){
        return owners[_ownerAddress];
    }

    function getAllOwners() public view returns (address[] memory){
        return ownersArray;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}