import React, { useState } from "react";
import { useCurrentAccount, useSignAndExecuteTransaction } from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { networkConfig } from "../config/networkConfig";

const EditSwapNum: React.FC<{ onSuccess: () => void }> = ({ onSuccess }) => {
    const currentAccount = useCurrentAccount();
    const { mutateAsync: signAndExecute, isError } = useSignAndExecuteTransaction();
    const PackageChallenge = networkConfig.testnet.packageChallenge;
    const AdminCap = networkConfig.testnet.adminCap;
    const SwapPool=networkConfig.testnet.flag_pool;
    const [loading, setLoading] = useState(false);
    const [num, setNum] = useState(100000);

    const create = async () => {
        if (!currentAccount?.address) {
            console.error("No connected account found.");
            return;
        }
        console.log("adress", currentAccount.address);
        setLoading(true);
        try {
            const tx = new Transaction();
            tx.setGasBudget(10000000);

            tx.moveCall({
                package: PackageChallenge,
                module: "challenge",
                function: "editSwapNum",
                // typeArguments: [Faucet],
                arguments: [
                    tx.object(AdminCap),
                    tx.object(SwapPool),
                    tx.pure.u64(10), //代币对象，测试前手动修改。
                ],
            });
            const result = await signAndExecute({ transaction: tx });
            if (result && !isError) {
                onSuccess();
            }
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    return (
      <div style={{ display: 'flex', alignItems: 'center' }}>
          <input
            type="text"
            placeholder="Enter amount"
            value={num}
            onChange={(e) => setNum(Number(e.target.value))} // 绑定输入事件
          />
          <button
            onClick={create}
            disabled={!num || loading} // 禁用按钮直到输入了amount且不在加载状态
          >
              {loading ? 'Loading...' : 'EditSwapNum'}
          </button>
      </div>
    );
};

export default EditSwapNum;



