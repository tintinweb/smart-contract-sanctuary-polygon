// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

// 849398 gas spended 828432 805577 748358 738769

// custom errorleri contract dısında tanımladıgımıza dikkat et.
error NotOwner();
error MinUsd();
error SendFailed();

contract FundMe {
    //import ettigimiz price converter library'sini uint256 larda kullanabilecek sekilde atadık.
    //msg.value bir uint256 oldugu icin PriceConverter kütüphanesindeki fonksiyonları msg.value ve diger uint256 larda cagırabilecegiz.
    using PriceConverter for uint256;

    //constant glabal variableleri sadece bir kere erisiyorsan ve sonra degistirmiyorsan kullanabilirsin. Böylece storage'da alan kaplamaz.(js deki memory alloc gibi)
    //constant degerlerde convension tüm harflerin büyük yazılmasıdır.
    //x dolar anlamına gelir getConversionRate ile karsılastırabilmek icin 1e18 ile carptık.
    uint public constant MINIMUM_USD = 0.01 * 1e18; // en az contribute edebilecegi amount. Chainlik oracle kullanarak bu coin'i usd'ye göre ayarlıcaz.

    //immitable constants gibidir fakat run time dır. Yani degiskenin degerini direk atamadıgın yerlerde ve sadece bir kere degisken atanan yerlerde immutable kullan
    //ancak degiskenin degerinide tanımladıgın yerde veriyorsan constant kullan. convension immitablelerin basına i_ ile isimlendirmektir.
    address public immutable i_owner; // contract owner. witraw fonksiyonunu sadece owner cagırabilir.

    address[] public funders; // contract'a para gönderen hesapların array'ini tutuyrouz.
    mapping(address => uint256) public addressToAmountFunded; // her funder'ın ne kadar gönderdigini tutuyoruz.

    modifier restricted() {
        //require(msg.sender == i_owner,"Only owner can call withraw");
        if (msg.sender != i_owner) {
            revert NotOwner(); //require yerene kendi error'umuzu throw ediyoruz. Bu yöntem data gas efficent. Yani gas save etmemizi saglar.
            //revert() bir işlemi yarıda keser. require() gibi ancak icine bir condition almıyor cagırılması yeterli.
        }
        _;
    }

    // chain'e göre degisebilecek bir price feed objesi olusturduk.
    address public priceFeed; //*her chain degistiginde sol dosyasına gelip manuel olarak address degistirmek yerine her parametre olarak yazmak yeterli.

    //msg.sender consturtor ve diger fonksiyonlarda olur cünkü fonksiyonu cagırandır global scope'da olmaz.
    constructor(address _priceFeed) {
        i_owner = msg.sender; //contract create edilirken sender contract'ı create edendir.
        priceFeed = _priceFeed;
    }

    // Contract'ı fundlamaya yarar.
    // Bir fonksiyonu ödeme alabilir hale "payable" kelimesiyle getiriyoruz.
    function fund() public payable {
        // 1-) Minimum fundlama miktarı en az 1 ETH olmalı.
        // Require islemi false döndürürse islem revert olur. Reverti return gibi düsün reverte kadar olan islemler icin gas harcanır
        // ancak reverti gecemezse revertten sonraki hiçbir islem icin gas harcanmaz. Revertten önce yaptıgı islemleri'de geri alır.
        // library fonkisyonlarının ilk aldıgı parametre cagırıldıgı degiskendir mesela msg.value.getConversionRate() == getConversionRate(msg.value)
        // eger birden fazla parametre alıyorsa getConversionRate() icine yazdıgımız ikinci parametre olarak gecer.
        // Unutma ilk parametre cagırıldıgı degisken ikinci parametre icine yazdıgımız ilk degisken.
        // require(msg.value.getConversionRate() >= MINIMUM_USD,"You are sending below to minimum contribute amount.");
        if (msg.value.getConversionRate(priceFeed) < MINIMUM_USD) {
            revert MinUsd();
        }
        // 1e18 1ETH yada 1Polygon vb. demektir. Buna *2 /2 vb. matematiksel islemler uygulayarak miktarı ayarlayabilirsin.

        // 2-) Para gönderen adresi funders array'ine ekliyoruz.
        funders.push(msg.sender);

        // 3-) Para gönderen adreslerin ne kadar gönderdigini mapping'e ekliyoruz.
        addressToAmountFunded[msg.sender] += msg.value; // COK ONEMLI += dedik çünkü birden fazla contribute yaparsa önceki miktarına eklesin istiyoruz. Bunu yapmazsan öncekini cotributionu sıfırlar sonuncuyu alır.
    }

    // Manager'ın fundlanan parayı cekmesini saglar.
    function withraw() public restricted {
        for (uint i = 0; i < funders.length; i++) {
            // 1-) Resetting mapping value
            addressToAmountFunded[funders[i]] = 0;
            // 2-) Resetting array
            funders = new address[](0); //new ile bos bir array construct ediyor ve funders'a atıyoruz. new ile construct ettiklerinde lengt () icine gelir.
            // 3-) Fund contract creator

            // 3 sekilde coin gönderebiliriz.

            // 1- transfer =>
            // contractaki tüm balance'ı withraw fonksiyonunu cagıran adrese gönderiyoruz.
            //* payable(msg.sender).transfer(address(this).balance); //this html'deki window gibi bu contractı işaret eder. address().balance verilen adresin icindeki miktarı verir.
            // msg.sender adresine ödeme yapabilmek icin payable() ile parse ediyoruz.
            // msg.sender address tipindedir. payable(msg.sender) payable address tipindedir.
            // eth gibi native blockchain tokenlerini sadece payable addresslere gönderebilirsin.
            // 2- send =>
            // transferde islem basarısız oldugunda error verir ve transationu revert eder ancak send'de true yada false bool return eder.
            // ancak send'de bool islemi revert etmez ve para gider bunu engellemek icin dönen bool'u kullanmalıyız.
            //* bool success = payable(msg.sender).send(address(this).balance);
            // require(success,"Send failed"); //bunu yaptıgımızda islem revert olur para gitmez sadece buraya kadarki gas harcanmıs olur.
            // 3- call(low level bir fonksiyon bir cok amac icin kullanılabilir) =>
            // solidity'de birden cok deger return eden fonksiyonları () ile destruct ediyoruz.
            // dataReturned'de call ile cagırlan fonksiyon bir deger döndürürse burada saklanır. callSuccess ise call'ın basarılı olup olmadıgı.
            // bytes'lar array oldukları icin memory yada storage belirtmeliyiz.
            (bool callSuccess, bytes memory dataReturned) = payable(msg.sender)
                .call{value: address(this).balance}("");
            // require(callSuccess,"Send failed"); //require'da gerceklesmesi gerekeni birinci parametreye yazıyoruz eger gerceklesmesse cıkacak mesajı ikinci parametreye yazıyoruz.
            if (!callSuccess) {
                revert SendFailed();
            }
            // Durumdan duruma degissede genelde önerilen native token transfer yöntemi call()'dır.
        }
    }

    // COK ONEMLI RECEIVE YADA FALLBACK OLMADAN CONTRACTA DIREK PARA GONDERMEYE CALISIRSAN ERROR VERIR VE TRANSACTION GITMEZ.
    // EGER RECEIVE VEYA FALLBACK'I TANIMLADIYSAN BUNLARI COK IYI HANDLE ETMELISIN YOKSA GIDEN PARAYI CEKEMEYEBILIRSIN.

    // User icine bir data bir fonksiyon belirlemeden direk contract'a para göndermeye calısırsa bu fonksiyon triggerlanır.
    receive() external payable {
        // böyle bir durumda direk fund fonksiyonunu calıstırıyoruz böylece userin direk gönderdigi para contribute etmis sayılıyor.
        fund();
    }

    fallback() external payable {
        // aynı sekilde transactionla birlikte datada göndermissa fund triggerlansın istiyoruz.
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Import ettigimiz inferfacelerin functionlarına constractımızdan erisebiliriz.
// dosyayı farklı bir file'a kaydedip oradan import edebilirdik ancak bunun yerine dosyayı githubdan remote import ediyoruz.
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// library'ler contract gibidirler ancak state variableleri alamazlar ve para alamaz ve gönderemezsin.
// library'deki tüm fonksiyonlar internal olurlar.
library PriceConverter {
    // Bir birim coin'in USD kur karsılıgını almaya yarar. Ör 1eth 3.200 USD gibi
    function getPrice(address _priceFeed) internal view returns (uint256) {
        // Bir contractin baska bir contract ile iletisime gecmesi icin 2 seye ihtiyacı vardır 1)ABI 2)ADDRESS
        // address 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        // ABI'ı tüm contactı copy paste ederek ulasabiliriz ancak bu kodu sisirir bunun yerine import ederek abi'ye ulasmalıyız.
        // import ettigimiz interface'den kullanmak icin bir instance olusturuyoruz.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        // latestRoundData birden fazla deger return ettigi icin her return ettigi degeri bu sekilde destruct ediyoruz.
        (
            ,
            int256 answer, // burade ihtiyacımız olan degisken bu ether fiyatının usd karsışıgını döndürür. Solidity'de decimal number olmadıgı icin fiyatı noktasız döndürür. Anlamak icin interface'deki decimals fonksiyonunu cagırabilirsin. // return ettigi kullanmadıgımız degiskenleri virgül ile ayrıdık.
            ,
            ,

        ) = priceFeed.latestRoundData();

        // int türünden olan answer yani price'ı uint() ile uinte parse ediyoruz. cünkü wei uint türünden ve ikisini karsılastırma yapmalıyız bu yüzden tiplerini esitliyoruz.
        return uint256(answer * 1e10); //answer yani price'ı wei ile karsılastırma yapabilmek icin 10 sıfırla carparak sıfırlarını esitledik.
        // 1e10'a 1e18(wei'deki decimal) - 1e08(solidity'deki usd'deki decimal) ile eristik.
    }

    // Wei tipinden verilen birimin getPrice()'dan aldıgı kurla usd karsılıgını verir.
    // library fonkisyonlarının ilk aldıgı parametre cagırıldıgı degiskendir mesela msg.value.getConversionRate() == getConversionRate(msg.value)
    // eger birden fazla parametre alıyorsa getConversionRate() icine yazdıgımız ikinci parametre olarak gecer.
    // Unutma ilk parametre cagırıldıgı degisken ikinci parametre icine yazdıgımız ilk degisken.
    function getConversionRate(uint256 _ethAmount, address _priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(_priceFeed); //eth price kurunu alır.
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18; //önce carp sonra böl 1e18= 1 birim eth or polygon demektir.
        return ethAmountInUsd;
    }
}