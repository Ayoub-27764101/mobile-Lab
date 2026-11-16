<?php

namespace public;

use App\Entity\User;
use App\Event\Listener\UserPasswordEncoderInterface;
use Doctrine\Persistence\Event\LifecycleEventArgs;

class UserListener
{ public function __construct(private readonly UserPasswordEncoderInterface $passwordEncoder){


}
public  function prePersist(LifecycleEventArgs $args)
{
    $user = $args->getObject();
    if($user instanceof  User){
        $user->setPassword($this->passwordEncoder->hashPassword($user, $user->getPassword()));

    }

}

}
