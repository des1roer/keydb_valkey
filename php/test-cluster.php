<?php

// Список "seed" нод - достаточно указать несколько, клиент сам узнает всю топологию
$seeds = [
    'valkey_node1:6379',  // используйте имена контейнеров, если PHP в Docker-сети
    'valkey_node2:6379',
    'valkey_node3:6379',
    'valkey_node4:6379',
    'valkey_node5:6379',
    'valkey_node6:6379',
];

// Если PHP снаружи Docker - используйте внешние порты:
// $seeds = ['127.0.0.1:7001', '127.0.0.1:7002', ...];

$password = getenv('VALKEY_PASSWORD') ?: 'your_secret_password';
$timeout  = 1.5;      // таймаут подключения
$readTimeout = 1.5;   // таймаут чтения
$persistent = false;  // использовать persistent connections

try {
    $cluster = new RedisCluster(
        name: null,           // null = автоопределение
        seeds: $seeds,
        timeout: $timeout,
        read_timeout: $readTimeout,
        persistent: $persistent,
        auth: $password       // пароль передается здесь (phpredis >= 5.3)
    );

    // Опционально, но важно для High Load:
    $cluster->setOption(RedisCluster::OPT_SLAVE_FAILOVER, RedisCluster::FAILOVER_DISTRIBUTE);
    // FAILOVER_DISTRIBUTE - распределяет чтения по репликам случайным образом

    // Проверка
    $cluster->set('test_key', 'Valkey Cluster' . new \DateTimeImmutable()->getTimestamp());

    echo $cluster->get('test_key');
    echo PHP_EOL .' -------- ';
    echo $cluster->get('ahhaah');

} catch (RedisClusterException $e) {
    echo "Cluster error: " . $e->getMessage();
}
