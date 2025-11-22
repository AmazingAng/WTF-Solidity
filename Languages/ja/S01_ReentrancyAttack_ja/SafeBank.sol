// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.21;

/**
 * @title SafeBank - チェック-エフェクト-インタラクションパターンによる安全な銀行コントラクト
 * @notice リエントランシー攻撃を防ぐためのパターン実装例
 * @dev checks-effect-interactionパターンを適用した安全なコントラクト
 */
contract SafeBankCEI {
    mapping (address => uint256) public balanceOf; // ユーザー残高のマッピング

    // イベント定義
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice etherを預け、残高を更新する
     * @dev ユーザーの残高を増加させる安全な関数
     */
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice チェック-エフェクト-インタラクションパターンを使用した安全な出金関数
     * @dev リエントランシー攻撃を防ぐため、先に状態を更新してから外部相互作用を行う
     *
     * パターンの説明：
     * 1. Checks（チェック）: 条件や残高の確認
     * 2. Effects（エフェクト）: 状態変数の更新
     * 3. Interactions（インタラクション）: 外部コントラクトとの相互作用
     */
    function withdraw() external {
        // ステップ1: Checks（チェック） - 残高を確認
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");

        // ステップ2: Effects（エフェクト） - 先に状態を更新
        // 【重要】送金前に残高を0にリセット
        // リエントランシー攻撃時、balanceOf[msg.sender]は既に0になっているため
        // 上記のrequireチェックで攻撃を阻止できる
        balanceOf[msg.sender] = 0;

        // ステップ3: Interactions（インタラクション） - 外部相互作用
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");

        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice 銀行コントラクトの総残高を取得
     * @return このコントラクトが保有するETHの総額
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice 特定ユーザーの残高を取得
     * @param user 残高を確認したいユーザーのアドレス
     * @return ユーザーの残高
     */
    function getUserBalance(address user) external view returns (uint256) {
        return balanceOf[user];
    }
}

/**
 * @title ProtectedBank - リエントランシーロックによる安全な銀行コントラクト
 * @notice リエントランシーガードを使用してリエントランシー攻撃を防ぐ
 * @dev nonReentrantモディファイアを使用した安全なコントラクト
 */
contract ProtectedBank {
    mapping (address => uint256) public balanceOf; // ユーザー残高のマッピング
    uint256 private _status; // リエントランシーロック用の状態変数

    // リエントランシーガードの状態定数
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    // イベント定義
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice コンストラクタ - リエントランシーロックを初期化
     */
    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @notice リエントランシーガードモディファイア
     * @dev 関数の再入を防ぐためのモディファイア
     *
     * 動作原理：
     * 1. 最初の呼び出し時：_status = 0 → チェック通過 → _status = 1に設定
     * 2. リエントランシー時：_status = 1 → チェック失敗 → revert
     * 3. 正常終了時：_status = 0に復元
     */
    modifier nonReentrant() {
        // 最初のnonReentrant呼び出し時、_statusは_NOT_ENTERED（0）になる
        require(_status == _NOT_ENTERED, "ReentrancyGuard: reentrant call");

        // この後のnonReentrantへの呼び出しはすべて失敗する
        _status = _ENTERED;

        _; // 関数本体を実行

        // 呼び出し終了、_statusを_NOT_ENTEREDに復元
        _status = _NOT_ENTERED;
    }

    /**
     * @notice etherを預け、残高を更新する
     * @dev ユーザーの残高を増加させる安全な関数
     */
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice リエントランシーロックで保護された出金関数
     * @dev nonReentrantモディファイアでリエントランシー攻撃を防ぐ
     */
    function withdraw() external nonReentrant {
        // 残高を確認
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");

        // ETHを送金（リエントランシーロックにより再入は阻止される）
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");

        // 残高を更新
        balanceOf[msg.sender] = 0;
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice 銀行コントラクトの総残高を取得
     * @return このコントラクトが保有するETHの総額
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice 特定ユーザーの残高を取得
     * @param user 残高を確認したいユーザーのアドレス
     * @return ユーザーの残高
     */
    function getUserBalance(address user) external view returns (uint256) {
        return balanceOf[user];
    }
}

/**
 * @title PullPaymentBank - プル支払いパターンによる安全な銀行コントラクト
 * @notice OpenZeppelinが推奨するPullPaymentパターンの実装例
 * @dev エスクロー方式により直接送金を避け、ユーザーが自発的に資金を引き出す仕組み
 */
contract PullPaymentBank {
    mapping (address => uint256) public balanceOf; // ユーザー残高のマッピング
    mapping (address => uint256) public pendingWithdrawals; // 出金待ちの残高

    // イベント定義
    event Deposit(address indexed user, uint256 amount);
    event WithdrawalRequested(address indexed user, uint256 amount);
    event WithdrawalCompleted(address indexed user, uint256 amount);

    /**
     * @notice etherを預け、残高を更新する
     * @dev ユーザーの残高を増加させる安全な関数
     */
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice 出金リクエスト関数
     * @dev 直接送金せず、出金可能額として記録する（Push → Pull変換）
     */
    function requestWithdrawal() external {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");

        // ユーザーの残高を出金待ち残高に移動
        balanceOf[msg.sender] = 0;
        pendingWithdrawals[msg.sender] += balance;

        emit WithdrawalRequested(msg.sender, balance);
    }

    /**
     * @notice 実際の出金実行関数
     * @dev ユーザーが自発的に資金を引き出す（Pull方式）
     *
     * Pull方式の利点：
     * 1. 外部コントラクトへの直接送金を避ける
     * 2. ユーザーが制御するタイミングで資金受取
     * 3. リエントランシーリスクの大幅な軽減
     */
    function withdraw() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No pending withdrawals");

        // 出金待ち残高をリセット
        pendingWithdrawals[msg.sender] = 0;

        // 資金をユーザーに送金
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");

        emit WithdrawalCompleted(msg.sender, amount);
    }

    /**
     * @notice 銀行コントラクトの総残高を取得
     * @return このコントラクトが保有するETHの総額
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice 特定ユーザーの残高を取得
     * @param user 残高を確認したいユーザーのアドレス
     * @return ユーザーの残高
     */
    function getUserBalance(address user) external view returns (uint256) {
        return balanceOf[user];
    }

    /**
     * @notice 特定ユーザーの出金待ち残高を取得
     * @param user 確認したいユーザーのアドレス
     * @return ユーザーの出金待ち残高
     */
    function getPendingWithdrawal(address user) external view returns (uint256) {
        return pendingWithdrawals[user];
    }
}