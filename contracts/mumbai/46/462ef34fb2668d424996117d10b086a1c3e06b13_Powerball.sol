/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

pragma solidity ^0.8.0;

/**
파워볼 컨트랙트는 복권 컨트랙트 중에서 가장 복잡하다.
티켓 구매와 다중 당첨금 지급을 모두 가진 순환 복권이다. 
 */
contract Powerball {
    struct Round {
        /**
        Round 구조체는 RecurringLottery과 유사하다.
         */
        uint256 endTime; // 티켓 구매 기한
        uint256 drawBlock; // 임의 숫자를 생성하는 데 사용할 미래의 블록 번호
        uint256[6] winningNumbers; // 여섯 개의 당첨번호 배열
        mapping(address => uint256[6][]) tickets; // 하나의 플레이어가 여러 티켓을 가질 수 있는 티켓 매핑
        /**
        솔리디티에서 다차원 배열은 자바나 C와는 다르다.
        솔리디티에서 uint256[6][]은 uint256[6]개의 원소를 갖는 동적 배열을 의미한다. 
         */
    }

    uint256 public constant TICKET_PRICE = 2e15; // 단일 티켓 가격, 0.002이더
    uint256 public constant MAX_NUMBER = 69;
    uint256 public constant MAX_POWERBALL_NUMBER = 26;
    uint256 public constant ROUND_LENGTH = 3 days; // 라운드 길이의 초 단위, 게임이 진행될 시간

    uint256 public round; // 현재 라운드
    mapping(uint256 => Round) public rounds; // 현재 라운드에 대한 정보를 Round 구조체로 매핑

    constructor() {
        round = 1;
        rounds[round].endTime = block.timestamp + ROUND_LENGTH;
    }

    /** 
    buy() 함수의 전반부는 입력 데이터에 대한 일련의 검사를 진행한다. 
    */
    function buy(uint256[6][] memory numbers) public payable {
        // 구매할 티켓 가격이 전달한 이더와 매치가 되는지 확인한다.
        require(numbers.length * TICKET_PRICE == msg.value);

        // Ensure the non-powerball numbers on each ticket are unique
        // 티켓의 각 번호가 유니크한지 검사한다.
        for (uint256 k = 0; k < numbers.length; k++) {
            for (uint256 i = 0; i < 4; i++) {
                for (uint256 j = i + 1; j < 5; j++) {
                    require(numbers[k][i] != numbers[k][j]);
                }
            }
        }

        // Ensure the picked numbers are within the acceptable range
        // 티켓의 각 번호가 적절한 범위 내에 있는지 검사한다.
        for (uint256 i = 0; i < numbers.length; i++) {
            for (uint256 j = 0; j < 6; j++) require(numbers[i][j] > 0); // 각 번호는 0보다 커야함
            for (uint256 j = 0; j < 5; j++)
                require(numbers[i][j] <= MAX_NUMBER); // 티켓 번호는 MAX_NUMBER보단 작아야 함
            require(numbers[i][5] <= MAX_POWERBALL_NUMBER); // 파워볼 번호(마지막 자리)는 최대 파워볼 번호보다 작아야 함
        }

        // check for round expiry
        // 라운드 마감 확인
        if (block.timestamp > rounds[round].endTime) {
            /**
            여기서 해결해야 할 문제는 drawBlock이다.
            drawBlock은 추첨 기간과 같은 역할을 한다.
            그러나 이 컨트랙트에서 한 라운드의 drawBlock은 다음 라운드의 첫번째 티켓 구매를 할 때까지 설정되지 않는다.
            이는 아무도 다음 라운드 티켓을 구매하지 않으면
            한 라운드를 위한 추첨이 영원히 지연됨을 의미한다. 
            또한 누군가 임의로 다음 라운드 티켓을 구매해 추첨을 트리거할 수도 있음을 의미한다.
             */
            rounds[round].drawBlock = block.number + 5;
            round += 1;
            rounds[round].endTime = block.timestamp + ROUND_LENGTH;
        }

        // 검사에 합격하면 해당 티켓으로 컨트랙트 상태를 업데이트한다.
        // 위에서 라운드 설정이 완료되면 해당 라운드의 티켓 풀에 티켓이 하나씩 들어간다.
        for (uint256 i = 0; i < numbers.length; i++)
            rounds[round].tickets[msg.sender].push(numbers[i]);
    }

    function drawNumbers(uint256 _round) public {
        // 이 함수는 해당 라운드의 우승 티켓이 될 6개 번호를 무작위로 추첨한다.
        uint256 drawBlock = rounds[_round].drawBlock; // 해당 라운드에 drawBlock이 있어야 추첨 진행을 했다를 의미함
        require(block.timestamp > rounds[_round].endTime); // 티켓 구매 마감이 되어야 함
        require(block.number >= drawBlock); // 추첨 기간이 끝나야 함
        require(rounds[_round].winningNumbers[0] == 0); //당첨 번호는 아직 설정되지 않았어야 함. 따라서 0과 비교함

        uint256 i = 0;
        uint256 seed = 0;
        // 파워볼 당첨 번호를 추첨한다.
        while (i < 5) {
            // 이 로직은 drawBlock으로부터 256블록(약 80분) 내에 실행되어야 한다.
            bytes32 source = blockhash(drawBlock);
            /**
            난수를 생성할 때 매번 동일한 블록해시를 재사용할 수 없다.
            그렇게 되면 동일한 수가 5번 연속으로 출력될 것이기 때문이다.
            그 대신 블록 수에 매번 고유한 숫자(이 경우 i)를 연결해 만든 바이트 문자열을 해시해 시드를 얻는다. 
             */
            bytes memory encodedSource = abi.encode(source, seed);
            bytes32 _rand = keccak256(encodedSource);
            uint256 numberDraw = (uint256(_rand) % MAX_NUMBER) + 1;

            // non-powerball numbers must be unique
            bool duplicate = false;
            for (uint256 j = 0; j < i; j++) {
                if (numberDraw == rounds[_round].winningNumbers[j]) {
                    duplicate = true;
                    seed++;
                    break;
                }
            }
            if (duplicate) continue;

            rounds[_round].winningNumbers[i] = numberDraw;
            i++;
            seed++;
        }
        bytes32 source = blockhash(drawBlock);
        bytes memory encodedSource = abi.encode(source, seed);
        bytes32 _rand = keccak256(encodedSource);
        uint256 powerballDraw = (uint256(_rand) % MAX_POWERBALL_NUMBER) + 1;
        rounds[_round].winningNumbers[5] = powerballDraw;
    }

    /**
    번호 추첨이 끝난 후, 당첨 티켓을 소지한 사용자는 해당 라운드에 대한
    보상을 청구할 수 있다.
     */
    function claim(uint256 _round) public {
        require(rounds[_round].tickets[msg.sender].length > 0); // 당첨자는 티켓을 소유하고 있어야 하고,
        require(rounds[_round].winningNumbers[0] != 0); // 당첨번호가 0이 아니어야 한다. (이는 당첨 번호가 추첨된 상태임을 의미)

        uint256[6][] storage myNumbers = rounds[_round].tickets[msg.sender];
        uint256[6] storage winningNumbers = rounds[_round].winningNumbers;

        uint256 payout = 0;
        for (uint256 i = 0; i < myNumbers.length; i++) {
            uint256 numberMatches = 0;
            for (uint256 j = 0; j < 5; j++) {
                for (uint256 k = 0; k < 5; k++) {
                    if (myNumbers[i][j] == winningNumbers[k])
                        numberMatches += 1;
                }
            }
            bool powerballMatches = (myNumbers[i][5] == winningNumbers[5]);

            // win conditions
            if (numberMatches == 5 && powerballMatches) {
                payout = address(this).balance;
                break;
            } else if (numberMatches == 5) payout += 1000 ether;
            else if (numberMatches == 4 && powerballMatches) payout += 50 ether;
            else if (numberMatches == 4)
                payout += 1e17; // .1 ether
            else if (numberMatches == 3 && powerballMatches)
                payout += 1e17; // .1 ether
            else if (numberMatches == 3)
                payout += 7e15; // .007 ether
            else if (numberMatches == 2 && powerballMatches)
                payout += 7e15; // .007 ether
            else if (powerballMatches) payout += 4e15; // .004 ether
        }

        // 설정된 payout으로 최종 상금 지급후 해당 라운드의 사용자 티켓을 삭제해
        // 중복 수령을 방지한다.
        delete rounds[_round].tickets[msg.sender];
        payable(msg.sender).transfer(payout);
    }

    /**
    솔리디티의 구조체가 public이라면 getter를 자동으로 생성해준다. 
    그러나 솔리디티는 반환되는 배열에 복합 자료형을 포함할 수 없다.
    따라서 매핑과 배열의 경우 자체 view() 함수를 생성해줘야 한다.
    */
    function ticketsFor(uint256 _round, address user)
        public
        view
        returns (uint256[6][] memory tickets)
    {
        return rounds[_round].tickets[user];
    }

    function winningNumbersFor(uint256 _round)
        public
        view
        returns (uint256[6] memory winningNumbers)
    {
        return rounds[_round].winningNumbers;
    }
}