<?php

use Lexik\Bundle\JWTAuthenticationBundle\Event\AuthenticationSuccessEvent;
class JwtUserListener
{
    public function onAutentificationSuccess(AutentificationSuccessEvent $event){
        $data = $event->getData();
        $user = $event->getUser();
        $payload = $data;
        $payload['id'] = $user->getId();
        $payload['firstname'] = $user->getId();
        $payload['lastname'] = $user->getLastname();
        $payload['email'] = $user->getEmail();
        $event->setData($payload);
    }

}
