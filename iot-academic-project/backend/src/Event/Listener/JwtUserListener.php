<?php

namespace App\Event\Listener;

use App\Entity\User;
use Lexik\Bundle\JWTAuthenticationBundle\Event\JWTCreatedEvent;

class JwtUserListener
{
    public function onJwtCreated(JWTCreatedEvent $event): void
    {
        $user = $event->getUser();

        if (!$user instanceof User) {
            return;
        }

        $payload = $event->getData();
        $payload['id']        = $user->getId();
        $payload['firstname'] = $user->getFirstname();
        $payload['lastname']  = $user->getLastname();
        $payload['email']     = $user->getEmail();

        $event->setData($payload);
    }
}
