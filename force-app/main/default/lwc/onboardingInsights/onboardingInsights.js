import { LightningElement, api } from 'lwc';

export default class OnboardingInsights extends LightningElement {
    @api summary = {};
    @api vendorProgramMetrics = [];

    get hasData() {
        return this.summary && Object.keys(this.summary).length > 0;
    }

    get statusDistribution() {
        if (!this.summary) return [];
        
        const distribution = [];
        const statuses = ['Not Started', 'In Process', 'Pending Initial Review', 'Complete', 'Denied', 'Expired'];
        const total = this.totalOnboarding || 1;
        
        for (const status of statuses) {
            const count = this.summary[status] || 0;
            if (count > 0) {
                const percentage = Math.round((count / total) * 100);
                distribution.push({
                    label: status,
                    value: count,
                    progressStyle: `width: ${percentage}%`
                });
            }
        }
        
        return distribution;
    }

    get totalOnboarding() {
        return this.summary['Total'] || 0;
    }

    get funnelData() {
        if (!this.summary) return [];
        
        const total = this.totalOnboarding || 1;
        const stages = [
            { stage: 'Not Started', count: this.summary['Not Started'] || 0 },
            { stage: 'In Process', count: this.summary['In Process'] || 0 },
            { stage: 'Pending Review', count: this.summary['Pending Initial Review'] || 0 },
            { stage: 'Complete', count: this.summary['Complete'] || this.summary['Setup Complete'] || 0 }
        ];
        
        return stages.map(stage => {
            const percentage = Math.round((stage.count / total) * 100);
            return {
                ...stage,
                progressStyle: `width: ${percentage}%`
            };
        });
    }

    get vendorProgramStats() {
        if (!this.vendorProgramMetrics || this.vendorProgramMetrics.length === 0) {
            return {
                total: 0,
                active: 0,
                draft: 0,
                totalDealers: 0
            };
        }

        let totalDealers = 0;
        let active = 0;
        let draft = 0;

        for (const program of this.vendorProgramMetrics) {
            totalDealers += program.DealersOnboarded || 0;
            if (program.Status === 'Active' && program.Active) {
                active++;
            } else if (program.Status === 'Draft') {
                draft++;
            }
        }

        return {
            total: this.vendorProgramMetrics.length,
            active: active,
            draft: draft,
            totalDealers: totalDealers
        };
    }
}

