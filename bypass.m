#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#import <unistd.h>

// Перехват getppid (обман проверки родительского процесса)
pid_t fake_getppid(void) {
    // Возвращаем 1 (launchd), как у обычного легитимного приложения
    return 1; 
}

// Перехват sysctl (обман детекта эмуляторов и отладки)
int fake_sysctl(int *name, u_int namelen, void *oldp, size_size_t *oldlenp, void *newp, size_t newlen) {
    // Если игра ищет признаки отладки (KERN_PROC_PID / P_TRACED)
    if (namelen >= 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID) {
        int res = sysctl(name, namelen, oldp, oldlenp, newp, newlen);
        if (res == 0 && oldp && *oldlenp >= sizeof(struct kinfo_proc)) {
            struct kinfo_proc *kp = (struct kinfo_proc *)oldp;
            // Сбрасываем флаг отладки в ноль
            kp->kp_proc.p_flag &= ~P_TRACED;
        }
        return res;
    }
    return sysctl(name, namelen, oldp, oldlenp, newp, newlen);
}

__attribute__((constructor)) static void init() {
    NSLog(@"[GrandBypass] Твик успешно загружен! Отключаем проверки...");
    // Здесь Sideloadly или утилита инжекции свяжет эти функции с оригинальными вызовами
}
