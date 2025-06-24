import React, { useEffect, useState } from 'react'
import { TbServerBolt, TbServerOff } from 'react-icons/tb';


export default function ServerLive() {
    const SERVER_PROBE = process.env.NEXT_PUBLIC_RAILS_BACKEND_PROBE;
    const [backendAlive, setBackendAlive] = useState<boolean>(false);
    
    useEffect(() => {
      const checkBackendStatus = async () => {
        try {
          const response = await fetch(`http://${SERVER_PROBE}`);
          if (response.ok) {
            setBackendAlive(true);
          } else {
            setBackendAlive(false);
          }
        } catch (error) {
          setBackendAlive(false);
        }
      };
      checkBackendStatus();
      const interval = setInterval(checkBackendStatus, 10000);
      return () => clearInterval(interval); 
    }, []);
    return (
      <div className='pr-1'>
        { backendAlive
          ? <TbServerBolt className='stroke-green-500' />
          : <TbServerOff className='stroke-red-500'/>
        }
      </div>
    )
  }