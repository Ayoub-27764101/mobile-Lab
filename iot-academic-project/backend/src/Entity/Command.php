<?php

namespace App\Entity;

use Apiplatform\Metadata\ApiResource;
use App\Repository\CommandRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: CommandRepository::class)]
#[ORM\Table(name: 'command')]
#[ApiResource]
class Command
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 30)]
    private ?string $actuator = null;

    #[ORM\Column(length: 10, options: ['check' => "action IN ('on', 'off')"])]
    private ?string $action = null;

    #[ORM\Column(nullable: true, options: ['check' => 'duration_seconds > 0'])]
    private ?int $durationSeconds = null;

    #[ORM\Column(length: 15, options: ['default' => 'pending', 'check' => "status IN ('pending', 'executed', 'failed', 'expired')"])]
    private ?string $status = null;

    #[ORM\Column(type: 'datetimetz_immutable', options: ['default' => 'CURRENT_TIMESTAMP'])]
    private ?\DateTimeImmutable $createdAt = null;

    #[ORM\Column(type: 'datetimetz_immutable', nullable: true)]
    private ?\DateTimeImmutable $executedAt = null;

    public function __construct()
    {
        $this->status = 'pending';
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getActuator(): ?string
    {
        return $this->actuator;
    }

    public function setActuator(string $actuator): static
    {
        $this->actuator = $actuator;

        return $this;
    }

    public function getAction(): ?string
    {
        return $this->action;
    }

    public function setAction(string $action): static
    {
        $this->action = $action;

        return $this;
    }

    public function getDurationSeconds(): ?int
    {
        return $this->durationSeconds;
    }

    public function setDurationSeconds(?int $durationSeconds): static
    {
        $this->durationSeconds = $durationSeconds;

        return $this;
    }

    public function getStatus(): ?string
    {
        return $this->status;
    }

    public function setStatus(string $status): static
    {
        $this->status = $status;

        return $this;
    }

    public function getCreatedAt(): ?\DateTimeImmutable
    {
        return $this->createdAt;
    }

    public function getExecutedAt(): ?\DateTimeImmutable
    {
        return $this->executedAt;
    }

    public function setExecutedAt(?\DateTimeImmutable $executedAt): static
    {
        $this->executedAt = $executedAt;

        return $this;
    }
}
